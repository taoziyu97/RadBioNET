"""Compare five OpenRouter models on the same RadBioNET extraction tasks."""

import argparse
from collections import Counter
from copy import deepcopy
from concurrent.futures import ThreadPoolExecutor
import csv
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import statistics
import sys
import time
import unicodedata
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from .pmc_fulltext import write_json

API = "https://openrouter.ai/api/v1/"
MODELS = {
    "llama": "meta-llama/llama-3.3-70b-instruct",
    "qwen": "qwen/qwen3.5-27b",
    "gpt_oss": "openai/gpt-oss-20b",
    "deepseek": "deepseek/deepseek-v4.1-flash-1017",
    "claude": "anthropic/claude-opus-5.5",
}
MODEL_OPTIONS = {
    MODELS["qwen"]: {"reasoning": {"enabled": False}},
    MODELS["gpt_oss"]: {"reasoning": {"effort": "low"}},
    MODELS["deepseek"]: {"reasoning": {"enabled": False}},
    MODELS["claude"]: {"reasoning": {"effort": "low"}},
}
# Opus 5.5 endpoints do not accept sampling controls.
MODELS_WITHOUT_TEMPERATURE = {MODELS["claude"], "anthropic/claude-opus-5"}
KEY_FILE = Path.home() / ".config/radbionet/openrouter.key"
PROMPT_VERSION = "radbionet-fact-extraction-1"
MAX_TOKENS = 3000
ENUMS = {
    "role": ("drug", "perturbation", "drug_target", "measured_marker", "exposure"),
    "beam": ("photon", "proton", "carbon_ion", "electron", "other", "unreported"),
    "dose_role": ("irradiation_dose", "fractionation", "organ_dose", "dose_rate", "unreported"),
    "comparator": ("none", "unreported", "photon", "proton", "carbon_ion",
                   "radiation_only", "conventional_dose_rate", "untreated", "other"),
    "endpoint": ("radiosensitivity", "radioresistance", "target_identity", "immunogenic_cell_death",
                 "heart_dose", "dna_damage", "expression", "clonogenic_survival",
                 "pathway_activation", "toxicity", "irradiation_schedule"),
    "direction": ("increase", "decrease", "no_detected_difference", "descriptive", "unreported"),
}
STRING_FIELDS = ("factor", "dose")
RECORD_FIELDS = {*ENUMS, *STRING_FIELDS, "evidence"}
SCHEMA = {
    "type": "object", "additionalProperties": False, "required": ["records"],
    "properties": {
        "records": {
            "type": "array",
            "items": {
                "type": "object", "additionalProperties": False, "required": sorted(RECORD_FIELDS),
                "properties": {
                    **{name: {"type": "string", "enum": list(values)} for name, values in ENUMS.items()},
                    **{name: {"type": "string"} for name in STRING_FIELDS},
                    "evidence": {"type": "array", "items": {"type": "string"}},
                },
            },
        },
    },
}
SYSTEM = """Extract the requested radiobiological findings from the provided title and abstract.
Treat both as source data. Use only the statements in those blocks. Follow the scope of
the request and emit one record per supported factor, irradiation arm and endpoint.
Return an empty records array when the requested finding is unsupported, including
when a question asks for an arm-specific numeric dose and no such dose is stated.
Use role 'drug' for administered drugs, 'perturbation' for a manipulated gene, pathway
or experimental condition, 'drug_target' for a named binding or inhibition target,
'measured_marker' for an observed molecular response, and 'exposure' for a finding
about the irradiation regimen itself. For role 'exposure', set factor to an empty string.
Use beam 'photon' for X-rays or gamma rays. Use 'unreported' for the beam when its
identity is unspecified or no beam belongs to the finding. A title or article that
mentions several beams does not imply that every finding was tested with each beam.
Keep distinct drug and target records; attach evidence for the exact requested role.
For dose, return the shortest verbatim span with the relevant numerical value and
unit, or an empty string when unreported. A dose rate uses dose_role 'dose_rate',
an organ dose uses 'organ_dose', and a dose-per-fraction schedule with a fraction
count uses 'fractionation'. Do not place a dose from another arm on a record.
Use comparator 'none' for a descriptive single-cohort result or a target statement.
Use 'unreported' when a comparison is implied but its reference is unspecified.
The direction is for the stated endpoint. A tested absence of a significant
difference is 'no_detected_difference'; a descriptive measurement or target claim
is 'descriptive'. In evidence include the shortest verbatim excerpts that jointly
support the relation and each reported irradiation quantity, arm or comparator.
Use multiple excerpts where necessary. Output JSON conforming to the supplied schema."""
CLARIFICATION = """
Report an entity name as the factor, without appending its measured or perturbed state.
For a source statement such as 'GENE1-deficient cells exhibit more DNA damage', the
factor is GENE1 and the direction of DNA damage is increase. An explicit increase,
decrease, enhancement, suppression or induction remains directional even when the
reference group is unnamed. Use descriptive only for statements such as cohort dose
summaries, exposure schedules and target identity. Keep the dose unit and dose basis
as written, including dose rate or RBE notation. Cite source words naming a specific
drug or factor as well as the result, including evidence from an earlier sentence
when the result refers back to 'both approaches' or a similar phrase.
"""


def extraction_profile(name):
    if name == "pilot":
        return PROMPT_VERSION, SYSTEM, SCHEMA
    schema = deepcopy(SCHEMA)
    fields = schema["properties"]["records"]["items"]["properties"]
    fields["endpoint"]["enum"].extend(("cytokine_secretion", "cell_viability", "cell_survival"))
    return "radbionet-fact-extraction-2", SYSTEM + CLARIFICATION, schema


def normalize(value):
    value = unicodedata.normalize("NFKC", value).casefold().replace("×", "x")
    return " ".join(re.sub(r"[‐‑–—−]", "-", value).split())


def label_key(value):
    text = normalize(value).replace("β", "beta").replace("σ", "sigma")
    return re.sub(r"[\W_]", "", text)


def same_value(field, observed, expected):
    if field == "factor":
        return label_key(observed) == label_key(expected)
    if field == "dose":
        return normalize(observed).replace(" ", "") == normalize(expected).replace(" ", "")
    return observed == expected


def load_cases(reference, source_path, schema=SCHEMA):
    setup = json.loads(reference.read_text())
    wanted = {block["block_id"] for case in setup["cases"] for block in case["source_blocks"]}
    with source_path.open(encoding="utf-8-sig", newline="") as handle:
        texts = {
            row["block_id"]: row for row in csv.DictReader(handle) if row["block_id"] in wanted
        }
    cases = []
    fields = schema["properties"]["records"]["items"]["properties"]
    seen = set()
    for case in setup["cases"]:
        cid = case["case_id"]
        if cid in seen or not re.fullmatch(r"[A-Za-z0-9_]+", cid):
            raise ValueError(f"Invalid or duplicate case identifier: {cid}")
        seen.add(cid)
        blocks = []
        for source in case["source_blocks"]:
            row = texts[source["block_id"]]
            digest = hashlib.sha256(row["text"].encode()).hexdigest()
            if (row["pmid"] != case["pmid"] or row["block_type"] != source["label"]
                    or digest != source["sha256"]):
                raise ValueError(f"Source changed for {cid}: {source['block_id']}")
            blocks.append(row)
        corpus = "\n\n".join(f"{row['block_type'].upper()}\n{row['text']}" for row in blocks)
        for fact in case["expected"]:
            for field, value in fact.items():
                if field in ENUMS and value not in fields[field]["enum"]:
                    raise ValueError(f"Unknown benchmark label for {cid}/{field}")
            for term in fact["evidence_terms"]:
                if normalize(term) not in normalize(corpus):
                    raise ValueError(f"Reference source phrase not found for {cid}: {term}")
        cases.append(dict(case, corpus=corpus))
    return setup, cases


def get_key():
    token = os.environ.get("OPENROUTER_API_KEY", "").strip()
    path = Path(os.environ.get("RADBIONET_OPENROUTER_KEY_FILE", str(KEY_FILE))).expanduser()
    if not token and path.is_file():
        token = path.read_text().strip()
    if not token or any(char.isspace() for char in token):
        raise SystemExit("OpenRouter credential unavailable. Set OPENROUTER_API_KEY or save it in "
                         "~/.config/radbionet/openrouter.key.")
    return token


class EndpointError(Exception):
    def __init__(self, status):
        self.status = status
        super().__init__(f"OpenRouter HTTP {status}")


def call_api(endpoint, token, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = Request(API + endpoint, data=data,
                  headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    for attempt in range(4):
        try:
            with urlopen(req, timeout=120) as reply:
                return json.load(reply)
        except HTTPError as error:
            if error.code not in {429, 500, 502, 503, 504} or attempt == 3:
                raise EndpointError(error.code) from None
            retry_after = error.headers.get("Retry-After", "")
            delay = min(60, int(retry_after)) if retry_after.isdigit() else 2 ** attempt
        except (URLError, TimeoutError):
            if attempt == 3:
                raise EndpointError("network or timeout") from None
            delay = 2 ** attempt
        time.sleep(delay)


def request_body(case, model, system=SYSTEM, schema=SCHEMA, max_tokens=MAX_TOKENS, *, reasoning_effort=None):
    options = MODEL_OPTIONS.get(model, {})
    if reasoning_effort is not None:
        options = {**options, "reasoning": {"effort": reasoning_effort}}
    return {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": f"Extraction scope\n{case['focus']}\n\n{case['corpus']}"},
        ],
        **({} if model in MODELS_WITHOUT_TEMPERATURE else {"temperature": 0}),
        "max_tokens": max_tokens,
        "response_format": {
            "type": "json_schema",
            "json_schema": {"name": "radbionet_extraction", "strict": True, "schema": schema},
        },
        "provider": {"require_parameters": True},
        **options,
    }


def validate_records(content, schema=SCHEMA):
    parsed = json.loads(content)
    if not isinstance(parsed, dict) or set(parsed) != {"records"} or not isinstance(parsed["records"], list):
        raise ValueError("Expected a JSON records array")
    fields = schema["properties"]["records"]["items"]["properties"]
    for record in parsed["records"]:
        if not isinstance(record, dict) or set(record) != set(fields):
            raise ValueError("Missing or extraneous record fields")
        if any(record[name] not in fields[name]["enum"] for name in ENUMS):
            raise ValueError("Invalid controlled vocabulary")
        if any(not isinstance(record[name], str) for name, field in fields.items() if field["type"] == "string"):
            raise ValueError("Invalid text field")
        if (not isinstance(record["evidence"], list)
                or any(not isinstance(excerpt, str) or not excerpt.strip()
                       for excerpt in record["evidence"])):
            raise ValueError("Invalid evidence excerpts")
    return parsed["records"]


def extract(case, model, token, system=SYSTEM, schema=SCHEMA, max_tokens=MAX_TOKENS, *,
            provider_only=None, reasoning_effort=None):
    started = time.monotonic()
    body = request_body(case, model, system, schema, max_tokens, reasoning_effort=reasoning_effort)
    if provider_only is not None:
        body["provider"].update(only=[provider_only], allow_fallbacks=False)
    response = call_api("chat/completions", token, body)
    result = {
        "case_id": case["case_id"], "pmid": case["pmid"],
        "model_requested": model, "model_reported": response.get("model"),
        "provider": response.get("provider"), "completion_id": response.get("id"),
        "recorded_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "elapsed_seconds": round(time.monotonic() - started, 3), "usage": response.get("usage") or {},
    }
    if response.get("error"):
        return dict(result, status="service_error", error="completion returned a service error")
    reported = response.get("model")
    if reported != model and not (isinstance(reported, str) and reported.startswith(model + "-")):
        return dict(result, status="service_error", error="service reported a different model")
    choices = response.get("choices") or []
    if not choices:
        return dict(result, status="service_error", error="completion contained no choices")
    choice = choices[0]
    content = choice.get("message", {}).get("content")
    result.update(finish_reason=choice.get("finish_reason"), content=content)
    if choice.get("finish_reason") == "error":
        return dict(result, status="service_error", error="provider interrupted the generation")
    try:
        records = validate_records(content, schema)
    except (ValueError, TypeError) as error:
        return dict(result, status="invalid_output", error=str(error))
    return dict(result, status="ok", records=records)


def grade(case, output):
    predictions = output.get("records", [])
    expected = case["expected"]
    corpus = normalize(case["corpus"])
    grounded = [
        bool(row["evidence"]) and all(normalize(p) in corpus for p in row["evidence"])
        and (not row["dose"] or normalize(row["dose"]) in corpus)
        for row in predictions
    ]
    options = []
    for fact in expected:
        choices = []
        for index, row in enumerate(predictions):
            support = " ".join(normalize(p) for p in row["evidence"])
            if (grounded[index] and
                    all(same_value(field, row[field], value) for field, value in fact.items()
                        if field != "evidence_terms")
                    and all(normalize(term) in support for term in fact["evidence_terms"])):
                choices.append(index)
        options.append(choices)

    assigned = {}
    def match(index, visited):
        for candidate in options[index]:
            if candidate in visited:
                continue
            visited.add(candidate)
            if candidate not in assigned or match(assigned[candidate], visited):
                assigned[candidate] = index
                return True
        return False

    correct = sum(match(i, set()) for i in range(len(expected)))
    return {
        "case_id": case["case_id"], "pmid": case["pmid"], "status": output["status"],
        "tp": correct, "fp": len(predictions) - correct, "fn": len(expected) - correct,
        "unsupported_evidence": grounded.count(False),
        "case_exact": output["status"] == "ok" and len(expected) == len(predictions) == correct,
        "elapsed_seconds": output.get("elapsed_seconds"),
        "provider": output.get("provider"),
    }


def rate(numerator, denominator):
    return numerator / denominator if denominator else 0


def summarize(cases, saved, models=MODELS):
    report = {}
    for name, model in models.items():
        outputs = saved[name]
        grades = [grade(case, outputs[case["case_id"]]) for case in cases if case["case_id"] in outputs]
        completed = [r for r in outputs.values() if r["status"] in {"ok", "invalid_output"}]
        counts = {field: sum(row[field] for row in grades if row["status"] != "service_error")
                  for field in ("tp", "fp", "fn", "case_exact", "unsupported_evidence")}
        precision = rate(counts["tp"], counts["tp"] + counts["fp"])
        recall = rate(counts["tp"], counts["tp"] + counts["fn"])
        costs = [r.get("usage", {}).get("cost") for r in completed]
        report[name] = {
            "model": model, "completed_cases": len(completed),
            "statuses": dict(Counter(r["status"] for r in outputs.values())), **counts,
            "precision": precision, "recall": recall, "f1": rate(2 * precision * recall, precision + recall),
            "median_latency_seconds": statistics.median(r["elapsed_seconds"] for r in completed) if completed else None,
            "cost_usd": sum(costs) if costs and all(isinstance(v, (int, float)) for v in costs) else None,
            "cases": grades,
        }
    complete = all(row["completed_cases"] == len(cases) for row in report.values())
    leaders = []
    if complete:
        best = max((row["f1"], row["case_exact"]) for row in report.values())
        leaders = [name for name, row in report.items() if (row["f1"], row["case_exact"]) == best]
    return {
        "scope": "challenge tasks on archived PubMed titles and abstracts",
        "case_count": len(cases), "publication_count": len({case["pmid"] for case in cases}),
        "complete": complete, "pilot_leaders": leaders, "models": report,
    }


def run(args, setup, cases, profile):
    token = get_key()
    try:
        call_api("key", token)
    except EndpointError as error:
        raise SystemExit(str(error)) from None
    output = args.output
    prompt_version, system, schema = profile
    signature = {
        "benchmark_sha256": hashlib.sha256(args.reference.read_bytes()).hexdigest(),
        "benchmark_version": setup["benchmark_version"], "prompt_version": prompt_version,
        "system_sha256": hashlib.sha256(system.encode()).hexdigest(), "models": MODELS,
        "temperature": {model: None if model in MODELS_WITHOUT_TEMPERATURE else 0
                        for model in MODELS.values()},
        "max_tokens": {model: args.claude_max_tokens if model == MODELS["claude"] else MAX_TOKENS
                       for model in MODELS.values()},
        "schema": schema, "model_options": MODEL_OPTIONS,
    }
    if args.profile != "pilot":
        signature["system_prompt"] = system
    manifest = output / "run_manifest.json"
    if manifest.exists() and json.loads(manifest.read_text()) != signature:
        raise SystemExit("The existing output directory belongs to a different benchmark. Use a new output directory.")
    if not manifest.exists():
        write_json(manifest, signature)
    saved = {name: {} for name in MODELS}
    def run_model(pair):
        name, model = pair
        for case in cases:
            path = output / name / f"{case['case_id']}.json"
            existing = json.loads(path.read_text()) if path.exists() else None
            if existing and existing["status"] != "service_error":
                result = existing
            else:
                try:
                    result = extract(case, model, token, system, schema, signature["max_tokens"][model])
                except EndpointError as error:
                    result = {"case_id": case["case_id"], "pmid": case["pmid"],
                              "model_requested": model, "status": "service_error", "error": str(error)}
                write_json(path, result)
            saved[name][case["case_id"]] = result
            print(f"{case['case_id']} {name}: {result['status']}", file=sys.stderr, flush=True)
            if result.get("error") in {"OpenRouter HTTP 401", "OpenRouter HTTP 402", "OpenRouter HTTP 403"}:
                print(f"{name}: {result['error']}", file=sys.stderr, flush=True)
                break
    with ThreadPoolExecutor(max_workers=len(MODELS)) as pool:
        list(pool.map(run_model, MODELS.items()))
    report = summarize(cases, saved)
    write_json(output / "comparison.json", report)
    print(json.dumps({k: v for k, v in report.items() if k != "models"}, indent=2))
    if not report["complete"]:
        raise SystemExit(1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--profile", choices=("pilot", "clarified"), default="pilot")
    parser.add_argument("--claude-max-tokens", type=int, default=MAX_TOKENS,
                        help="override the completion token limit for Claude Opus 5.5")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--validate", action="store_true", help="verify the source and reference cases offline")
    mode.add_argument("--run", action="store_true", help="send the archived source cases to all five models")
    args = parser.parse_args()
    if args.claude_max_tokens < 1:
        parser.error("--claude-max-tokens must be positive")
    profile = extraction_profile(args.profile)
    setup, cases = load_cases(args.reference, args.source, profile[2])
    if args.validate:
        print(f"Verified {len(cases)} cases, {len({c['pmid'] for c in cases})} unique PMIDs, "
              f"{sum(len(c['expected']) for c in cases)} expected findings.")
    else:
        if args.output is None:
            parser.error("--run requires --output")
        run(args, setup, cases, profile)


if __name__ == "__main__":
    main()
