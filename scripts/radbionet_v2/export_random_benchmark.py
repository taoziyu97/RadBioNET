"""Export the completed seed-2026 evaluation as R-ready tables."""
from collections import defaultdict
import hashlib
import json
from pathlib import Path

from .model_comparison import MODELS, extraction_profile, grade, load_cases
from .pmc_fulltext import write_csv
from .random_benchmark import DRAWS, OUTPUT, SOURCE

MODEL_LABELS = {
    "llama": "Llama 3.3 70B", "qwen": "Qwen3.5-27B", "gpt_oss": "GPT-OSS 20B",
    "deepseek": "DeepSeek V4.1 Flash 1017", "claude": "Claude Opus 5.5",
}


def ratio(num, den):
    return num / den if den else None


def group_metrics(rows):
    tp, fp, fn, exact = (sum(row[name] for row in rows) for name in ("tp", "fp", "fn", "case_exact"))
    return {
        "tasks": len(rows), "reference_relations": tp + fn, "predicted_relations": tp + fp,
        "tp": tp, "fp": fp, "fn": fn, "exact_tasks": exact, "exact_task_rate": ratio(exact, len(rows)),
        "precision": ratio(tp, tp + fp), "recall": ratio(tp, tp + fn), "f1": ratio(2 * tp, 2 * tp + fp + fn),
    }


def export():
    _, _, schema = extraction_profile("clarified")
    tasks, models, categories = [], [], []
    completion_ids, pmids = set(), set()
    for split in DRAWS:
        ref = OUTPUT / f"{split}_reference.json"
        folder = OUTPUT / f"{split}_run"
        manifest = json.loads((folder / "run_manifest.json").read_text())
        if manifest["benchmark_sha256"] != hashlib.sha256(ref.read_bytes()).hexdigest():
            raise ValueError(f"Reference changed after scoring: {ref}")
        _, cases = load_cases(ref, SOURCE, schema)
        current_pmids = {case["pmid"] for case in cases}
        if pmids & current_pmids or len(current_pmids) != len(cases):
            raise ValueError("PMIDs overlap between tasks.")
        pmids.update(current_pmids)
        run = json.loads((folder / "comparison.json").read_text())
        if not run["complete"]:
            raise ValueError(f"Incomplete run: {folder}")
        for key, model in MODELS.items():
            common = {"split": split, "model_key": key, "model": MODEL_LABELS[key], "model_id": model}
            rows, groups = [], defaultdict(list)
            for case in cases:
                cid = case["case_id"]
                raw = json.loads((folder / key / f"{cid}.json").read_text())
                if (raw["model_requested"], raw["case_id"], raw["pmid"]) != (model, cid, case["pmid"]):
                    raise ValueError(f"Output belongs to a different task: {cid}")
                ident = raw["completion_id"]
                if not ident or ident in completion_ids:
                    raise ValueError(f"Missing or repeated completion ID for {cid}")
                completion_ids.add(ident)
                score = grade(case, raw)
                row = {**common, "task_type": case["task_type"], "sampling_pool": case["sampling_pool"],
                       "draw_rank": case["draw_rank"], **score, "case_exact": int(score["case_exact"]),
                       "reference_relations": len(case["expected"]), "predicted_relations": len(raw.get("records", [])),
                       "completion_id": ident, "model_reported": raw["model_reported"],
                       "finish_reason": raw.get("finish_reason"), "cost_usd": raw["usage"].get("cost")}
                rows.append(row)
                groups[case["task_type"]].append(row)
            calculated = group_metrics(rows)
            observed = run["models"][key]
            for name in ("tp", "fp", "fn", "precision", "recall", "f1"):
                if abs((calculated[name] or 0) - observed[name]) > 1e-12:
                    raise ValueError(f"Score mismatch: {split}, {key}, {name}")
            tasks.extend(rows)
            models.append({**common, **calculated, "valid_json_tasks": observed["statuses"].get("ok", 0),
                           "cost_usd": observed["cost_usd"], "median_latency_seconds": observed["median_latency_seconds"]})
            categories.extend({**common, "task_type": name, **group_metrics(block)}
                              for name, block in groups.items())
    for filename, rows in (("model_metrics.csv", models), ("task_scores.csv", tasks),
                           ("task_type_metrics.csv", categories)):
        write_csv(OUTPUT / filename, list(rows[0]), rows)
    print(f"Verified {len(completion_ids)} distinct completions from {len(pmids)} publications.")


if __name__ == "__main__":
    export()
