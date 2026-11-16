"""Draw publication audits and replay a versioned beam/dose extraction revision."""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import random
import re
import sys

from .model_comparison import (
    MAX_TOKENS, EndpointError, extract, extraction_profile, get_key, grade, load_cases,
    normalize, same_value, summarize,
)
from .pmc_fulltext import csv_rows, write_json

MODEL = "anthropic/claude-opus-5"
PROVIDER = "claude-on-aws"
PROVIDER_NAME = "Claude Platform on AWS"
REVISION = "radbionet-fact-extraction-3-arm-evidence"
CHECK_VERSION = "radbionet-arm-evidence-check-1"
FEATURES = ("beam_evidence", "dose_evidence")
BEAM_NAMES = {
    "photon": r"\b(?:photons?|x[ -]?rays?|gamma[ -]?(?:rays?|irradiation|radiation))\b|γ[ -]?(?:rays?|irradiation|radiation)",
    "proton": r"\b(?:protons?|impt)\b",
    "carbon_ion": r"\b(?:carbon[ -]ions?|c[ -]ions?)\b",
    "electron": r"\belectrons?\b",
}
BEAM_PATTERNS = {beam: re.compile(pattern) for beam, pattern in BEAM_NAMES.items()}
ARM_INSTRUCTIONS = """
Report a specific beam only if a quotation explicitly identifies that beam for
the irradiation arm associated with the requested finding. Put that quotation in
beam_evidence. Irradiation, radiotherapy, and ionizing radiation alone leave the
beam unreported. If the beam is unreported, return an empty beam_evidence string.
For a nonempty dose, include a dose_evidence quotation that contains the reported
dose expression and links it to the same arm. A shared dose can be assigned to
several arms when the source explicitly links it to each of them. Exclude a dose
described for a different arm, a pooled cohort, or a background treatment when
the requested index arm has no attributable dose. Return an empty dose and empty
dose_evidence when the dose cannot be assigned. Preserve the original dose units
and bases, including explicit physical-dose, RBE or dose-rate notation.
"""


def profiles():
    version, prompt, schema = extraction_profile("clarified")
    revised = deepcopy(schema)
    fields = revised["properties"]["records"]["items"]
    fields["required"].extend(FEATURES)
    for key in FEATURES:
        fields["properties"][key] = {"type": "string"}
    return {
        "baseline": (version, prompt, schema),
        "revised": (REVISION, prompt + ARM_INSTRUCTIONS, revised),
    }


def publication_sample(pmids, seed):
    if not pmids or any(not re.fullmatch(r"[1-9][0-9]*", pmid) for pmid in pmids):
        raise ValueError("The publication frame must contain valid PMIDs.")
    if len(set(pmids)) != len(pmids):
        raise ValueError("Duplicate PMIDs in the publication frame.")
    pmids = sorted(pmids, key=int)
    batches = []
    for offset in range(0, len(pmids), 200):
        batch = pmids[offset:offset + 200]
        batch_id = offset // 200 + 1
        batch_seed = f"{seed}:{batch_id}"
        n = min(10, len(batch))
        selected = random.Random(batch_seed).sample(batch, n)
        batches.append({
            "batch_id": batch_id, "batch_seed": batch_seed, "population_size": len(batch),
            "sample_size": n, "inclusion_probability": n / len(batch),
            "sampled_pmids": sorted(selected, key=int),
        })
    return batches


def sample(frame, seed, output):
    if output.exists():
        raise ValueError("Audit draw already exists. Use a new file for a new frozen frame.")
    rows = list(csv_rows(frame))
    if not rows or "pmid" not in rows[0]:
        raise ValueError("The frozen publication frame requires a pmid column.")
    batches = publication_sample([row["pmid"].strip() for row in rows], seed)
    write_json(output, {
        "root_seed": seed, "python_version": sys.version.split()[0],
        "frame_sha256": hashlib.sha256(frame.read_bytes()).hexdigest(), "frame_size": len(rows),
        "batches": batches,
    })
    print(f"Drew {sum(batch['sample_size'] for batch in batches)} PMIDs across {len(batches)} batches.")


def evidence_checks(corpus, records):
    source = normalize(corpus)
    flags = []

    def add(index, field, reason):
        flags.append({"record_index": index, "field": field, "reason": reason})

    for index, record in enumerate(records):
        beam, dose = record["beam"], normalize(record["dose"])
        beam_quote = normalize(record["beam_evidence"])
        dose_quote = normalize(record["dose_evidence"])
        if beam == "unreported":
            if beam_quote:
                add(index, "beam", "unexpected_quote_for_unreported_beam")
        elif not beam_quote or beam_quote not in source:
            add(index, "beam", "beam_quote_missing_from_source")
        elif beam not in BEAM_PATTERNS or not BEAM_PATTERNS[beam].search(beam_quote):
            add(index, "beam", "specific_beam_not_verified_by_quote")
        if not dose:
            if dose_quote:
                add(index, "dose", "unexpected_quote_for_blank_dose")
        elif not dose_quote or dose_quote not in source or dose not in dose_quote:
            add(index, "dose", "reported_dose_not_found_in_source_quote")
        elif beam in BEAM_PATTERNS:
            mentions = {label for label, pattern in BEAM_PATTERNS.items() if pattern.search(dose_quote)}
            if mentions != {beam}:
                add(index, "dose", "dose_to_arm_link_requires_review")
    return flags


def differences(case, response):
    # Attribute field discrepancies only when a factor/endpoint has a unique pair.
    if response["status"] != "ok":
        return [{"reason": response["status"]}]
    observed = response["records"]
    expected = case["expected"]
    details = []
    for number, fact in enumerate(expected):
        matches = [i for i, row in enumerate(observed)
                   if row["endpoint"] == fact["endpoint"] and same_value("factor", row["factor"], fact["factor"])]
        same_key = [row for row in expected if row["endpoint"] == fact["endpoint"]
                    and same_value("factor", row["factor"], fact["factor"])]
        if len(matches) == len(same_key) == 1:
            i = matches[0]
            field_diffs = {
                k: {"expected": v, "observed": observed[i][k]}
                for k, v in fact.items()
                if k != "evidence_terms" and not same_value(k, observed[i][k], v)
            }
            if field_diffs:
                details.append({"reference_index": number, "record_index": i, "fields": field_diffs})
    return details


def audit(sample_path, inference_input, reference, source, predictions, output):
    draw = json.loads(sample_path.read_text())
    selected = {pmid for batch in draw["batches"] for pmid in batch["sampled_pmids"]}
    if len(selected) != sum(batch["sample_size"] for batch in draw["batches"]):
        raise ValueError("Repeated or missing sampled PMIDs.")
    _, cases = load_cases(reference, source, profiles()["baseline"][2])
    if len(cases) != len(selected) or {case["pmid"] for case in cases} != selected:
        raise ValueError("Provide one reviewed case for every sampled PMID.")
    input_cases = {row["case_id"]: row for row in json.loads(inference_input.read_text())["cases"]}
    results = []
    for case in cases:
        cid = case["case_id"]
        original = input_cases.get(cid, {})
        if any(case[key] != original.get(key) for key in ("pmid", "source_blocks", "focus")):
            raise ValueError(f"The review must use the same archived source and scope as inference: {cid}")
        raw = json.loads((predictions / f"{cid}.json").read_text())
        if (raw["case_id"], raw["pmid"]) != (cid, case["pmid"]):
            raise ValueError(f"Prediction belongs to a different source: {cid}")
        flags = []
        for index, row in enumerate(raw.get("records", [])):
            if all(name in row for name in FEATURES):
                flags.extend(dict(flag, record_index=index) for flag in evidence_checks(case["corpus"], [row]))
        results.append({
            **grade(case, raw), "quality_flags": flags, "field_discrepancies": differences(case, raw),
        })
    counts = {key: sum(row[key] for row in results) for key in ("tp", "fp", "fn", "case_exact")}
    write_json(output, {
        "sample_sha256": hashlib.sha256(sample_path.read_bytes()).hexdigest(),
        "inference_input_sha256": hashlib.sha256(inference_input.read_bytes()).hexdigest(),
        "reference_sha256": hashlib.sha256(reference.read_bytes()).hexdigest(),
        "reference_status": json.loads(reference.read_text())["reference_status"],
        "counts": counts, "status_counts": dict(Counter(row["status"] for row in results)),
        "cases": results,
    })


def replay(reference, source, output):
    configurations = profiles()
    _, cases = load_cases(reference, source, configurations["baseline"][2])
    signatures = {
        "reference_sha256": hashlib.sha256(reference.read_bytes()).hexdigest(),
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "model": MODEL, "provider_only": PROVIDER, "reasoning_effort": "low",
        "max_tokens": MAX_TOKENS, "temperature": None, "fallbacks": False,
        "profiles": configurations, "review_rules": CHECK_VERSION,
    }
    manifest = output / "run_manifest.json"
    if manifest.exists():
        if json.loads(manifest.read_text()) != json.loads(json.dumps(signatures)):
            raise ValueError("Replay inputs or configuration changed. Use a new output directory.")
    else:
        write_json(manifest, signatures)
    token = get_key()

    def run_profile(item):
        name, (_, prompt, schema) = item
        records = {}
        for case in cases:
            cid = case["case_id"]
            path = output / name / f"{cid}.json"
            raw = json.loads(path.read_text()) if path.exists() else None
            if raw is None or raw["status"] == "service_error":
                try:
                    raw = extract(case, MODEL, token, prompt, schema, provider_only=PROVIDER,
                                  reasoning_effort="low")
                except EndpointError as error:
                    raw = {"case_id": cid, "pmid": case["pmid"], "model_requested": MODEL,
                           "status": "service_error", "error": str(error)}
                if raw.get("provider") not in (None, PROVIDER_NAME):
                    raw.update(status="service_error", error="Unexpected provider")
                write_json(path, raw)
            records[cid] = raw
            print(f"{name} {cid}: {raw['status']}", flush=True)
            if raw.get("error") in {"OpenRouter HTTP 401", "OpenRouter HTTP 402", "OpenRouter HTTP 403"}:
                break
        return name, records

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = dict(pool.map(run_profile, configurations.items()))
    report = summarize(cases, results, models=dict.fromkeys(configurations, MODEL))
    report["profiles"] = report.pop("models")
    report.pop("pilot_leaders")
    report["scope"] = "development diagnostic replay on previously used abstract tasks"
    report["reference_status"] = json.loads(reference.read_text())["reference_status"]
    detail = []
    for case in cases:
        cid = case["case_id"]
        for name, outputs in results.items():
            if cid not in outputs:
                continue
            result = outputs[cid]
            rows = result.get("records", [])
            flags = evidence_checks(case["corpus"], rows) if name == "revised" and result["status"] == "ok" else []
            detail.append({
                "profile": name, **grade(case, result), "quality_flags": flags,
                "field_discrepancies": differences(case, result),
            })
    report["tasks"] = detail
    report["quality_flags_by_reason"] = dict(Counter(
        flag["reason"] for task in detail for flag in task["quality_flags"]
    ))
    write_json(output / "comparison.json", report)
    if not report["complete"]:
        raise SystemExit("Replay incomplete. Reuse the output directory to resume.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    draw = commands.add_parser("sample", help="draw up to ten PMIDs from each fixed batch of 200")
    draw.add_argument("--frame", required=True, type=Path)
    draw.add_argument("--seed", type=int, default=2026)
    draw.add_argument("--output", required=True, type=Path)
    compare = commands.add_parser("replay", help="compare baseline and revised prompts with Claude Opus 5")
    compare.add_argument("--reference", required=True, type=Path)
    compare.add_argument("--source", required=True, type=Path)
    compare.add_argument("--output", required=True, type=Path)
    score = commands.add_parser("audit", help="compare sampled outputs with adjudicated annotations offline")
    score.add_argument("--sample", required=True, type=Path)
    score.add_argument("--inference-input", required=True, type=Path)
    score.add_argument("--reference", required=True, type=Path)
    score.add_argument("--source", required=True, type=Path)
    score.add_argument("--predictions", required=True, type=Path)
    score.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.command == "sample":
        sample(args.frame, args.seed, args.output)
    elif args.command == "audit":
        audit(args.sample, args.inference_input, args.reference, args.source, args.predictions, args.output)
    else:
        replay(args.reference, args.source, args.output)


if __name__ == "__main__":
    main()
