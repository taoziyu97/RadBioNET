"""Compare four prompting conditions for RadBioNET relation extraction."""

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import sys

from .model_comparison import (
    API, MAX_TOKENS, MODELS, MODEL_OPTIONS, EndpointError, call_api, extract,
    extraction_profile, get_key, grade, load_cases, normalize, summarize, validate_records,
)
from .pmc_fulltext import write_json

MODEL = MODELS["claude"]
PROVIDER = "claude-on-aws"
PROVIDER_NAME = "Claude Platform on AWS"
VERIFICATION = """
Before emitting JSON, check each draft record against the target source. Check that
the named factor's role matches the action or observation, the dose and modality
belong to the same irradiation arm, and the comparator and direction fit the stated
endpoint. Locate every copied quotation and reported dose in the target text. If
support is absent, leave the relevant source-omitted field unreported as specified
or remove the unsupported record. Emit only the final JSON.
"""
DEMOS = (
    {
        "scope": "Extract irradiation schedules for the proton and photon groups.",
        "text": "The proton group received 50 Gy(RBE) in 25 fractions. The photon group received 54 Gy in 27 fractions.",
        "records": [
            {"factor": "", "role": "exposure", "beam": "proton", "dose": "50 Gy(RBE) in 25 fractions",
             "dose_role": "fractionation", "comparator": "none", "endpoint": "irradiation_schedule",
             "direction": "descriptive", "evidence": ["The proton group received 50 Gy(RBE) in 25 fractions."]},
            {"factor": "", "role": "exposure", "beam": "photon", "dose": "54 Gy in 27 fractions",
             "dose_role": "fractionation", "comparator": "none", "endpoint": "irradiation_schedule",
             "direction": "descriptive", "evidence": ["The photon group received 54 Gy in 27 fractions."]},
        ],
    },
    {
        "scope": "Extract the drug's molecular target.",
        "text": "The experimental compound QZ-91 inhibits the kinase KINZ. QZ-91 increased sensitivity to X-rays.",
        "records": [
            {"factor": "KINZ", "role": "drug_target", "beam": "unreported", "dose": "",
             "dose_role": "unreported", "comparator": "none", "endpoint": "target_identity",
             "direction": "descriptive", "evidence": ["The experimental compound QZ-91 inhibits the kinase KINZ."]},
        ],
    },
    {
        "scope": "Extract the numerical dose of carbon-ion irradiation.",
        "text": "Cells received either carbon ions or 5 Gy of X-rays before the viability assay.",
        "records": [],
    },
)


def make_prompts(base, schema):
    examples = ["Synthetic demonstrations follow. Extract records only from the task supplied separately."]
    for demo in DEMOS:
        response = json.dumps({"records": demo["records"]})
        validate_records(response, schema)
        examples.append(f"Extraction scope\n{demo['scope']}\nSource\n{demo['text']}\nOutput\n{response}")
    demonstration = "\n\n" + "\n\n".join(examples) + "\n"
    return {
        "zero_shot": base,
        "few_shot": base + demonstration,
        "evidence_check": base + VERIFICATION,
        "few_shot_evidence_check": base + VERIFICATION + demonstration,
    }


def measure_emitted_records(cases, outputs):
    results = Counter()
    for case in cases:
        output = outputs.get(case["case_id"], {})
        corpus = normalize(case["corpus"])
        for record in output.get("records", []):
            results["records_emitted"] += 1
            if record["factor"]:
                results["nonempty_factors"] += 1
                results["factor_mention_found"] += normalize(record["factor"]) in corpus
            results["records_with_all_quotes_found"] += bool(record["evidence"]) and all(
                normalize(passage) in corpus for passage in record["evidence"]
            )
    return {key: results[key] for key in (
        "records_emitted", "nonempty_factors", "factor_mention_found", "records_with_all_quotes_found",
    )}


def run(reference, source, output):
    baseline, base, schema = extraction_profile("clarified")
    setup, cases = load_cases(reference, source, schema)
    prompts = make_prompts(base, schema)
    manifest_path = output / "run_manifest.json"
    manifest = {
        "benchmark_version": setup["benchmark_version"], "baseline_prompt_version": baseline,
        "benchmark_sha256": hashlib.sha256(reference.read_bytes()).hexdigest(),
        "model": MODEL, "provider": PROVIDER, "model_options": MODEL_OPTIONS[MODEL],
        "max_tokens": MAX_TOKENS, "endpoint": API + "chat/completions",
        "schema": schema, "system_prompts": prompts,
    }
    if manifest_path.exists():
        if json.loads(manifest_path.read_text()) != manifest:
            raise SystemExit("The output directory does not match these benchmark settings.")
    else:
        write_json(manifest_path, manifest)
    token = get_key()
    try:
        call_api("key", token)
    except EndpointError as error:
        raise SystemExit(str(error)) from None

    def run_condition(item):
        index, (condition, system) = item
        collected = {}
        # Offset starting cases so simultaneous requests use different source abstracts.
        shift = index % len(cases)
        for case in cases[shift:] + cases[:shift]:
            path = output / condition / f"{case['case_id']}.json"
            result = json.loads(path.read_text()) if path.exists() else None
            if result is None or result["status"] == "service_error":
                try:
                    result = extract(case, MODEL, token, system, schema, provider_only=PROVIDER)
                except EndpointError as error:
                    result = {"case_id": case["case_id"], "pmid": case["pmid"], "model_requested": MODEL,
                              "status": "service_error", "error": str(error)}
                if result.get("provider") not in (None, PROVIDER_NAME):
                    result.update(status="service_error", error="Unexpected serving provider")
                write_json(path, result)
            collected[case["case_id"]] = result
            print(f"{condition} {case['case_id']}: {result['status']}", file=sys.stderr, flush=True)
            if result.get("error") in {"OpenRouter HTTP 401", "OpenRouter HTTP 402", "OpenRouter HTTP 403"}:
                print(result["error"], file=sys.stderr, flush=True)
                break
        return condition, collected

    with ThreadPoolExecutor(max_workers=len(prompts)) as pool:
        saved = dict(pool.map(run_condition, enumerate(prompts.items())))
    report = summarize(cases, saved, models=dict.fromkeys(prompts, MODEL))
    report["conditions"] = report.pop("models")
    report["leading_conditions"] = report.pop("pilot_leaders")
    report["reference_record_count"] = sum(len(case["expected"]) for case in cases)
    locator_cases = [
        dict(case, expected=[dict(row, evidence_terms=[]) for row in case["expected"]])
        for case in cases
    ]
    for condition, result in report["conditions"].items():
        outputs = saved[condition]
        result.update(measure_emitted_records(cases, outputs))
        # Keep the field and source checks while dropping required reference phrases.
        result["true_positives_without_evidence_phrase_requirement"] = sum(
            grade(case, outputs[case["case_id"]])["tp"]
            for case in locator_cases if case["case_id"] in outputs
        )
    write_json(output / "comparison.json", report)
    if not report["complete"]:
        raise SystemExit("Prompt comparison is incomplete. Resume using the same output directory.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    run(args.reference, args.source, args.output)
