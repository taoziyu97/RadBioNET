"""Freeze PubMed screening pools and assemble a seeded extraction benchmark."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import random
import re
import sys

from .model_comparison import extraction_profile, load_cases, normalize
from .pmc_fulltext import csv_rows, write_csv, write_json

SEED = 2026
ROOT = Path("Scientific_Data_submission")
SOURCE = ROOT / "data_v2_prepared/local_evidence/text_blocks.csv"
OUTPUT = ROOT / "random_benchmark_seed2026"
DRAWS = {
    "selection": {"factor_role": 2, "outcome": 2, "photon": 1, "proton": 1,
                  "carbon_ion": 1, "unsupported_dose": 1, "unsupported_comparison": 1},
    "development": {"factor_role": 4, "outcome": 4, "photon": 2, "proton": 1,
                    "carbon_ion": 1, "unsupported_dose": 1, "unsupported_comparison": 1},
}
BEAMS = {
    "photon": re.compile(r"\b(?:x[- ]?rays?|photons?|gamma[- ]?rays?)\b", re.I),
    "proton": re.compile(r"\bprotons?\b", re.I),
    "carbon_ion": re.compile(r"\bcarbon[- ]ions?\b", re.I),
}
RADIATION = re.compile(r"\b(?:irradiat\w+|ionizing radiation|x[- ]?rays?|radiotherap\w+|radiation treatment)\b", re.I)
ROLE = re.compile(r"\b(?:knockdown|knockout|deplet(?:ion|ed)|silenc\w+|overexpress\w+|inhibit\w+|deficien\w+)\b", re.I)
MOLECULAR = re.compile(r"\b(?:gene|protein|kinase|receptor|pathway|signaling|expression|crispr|sirna)\b", re.I)
OUTCOME = re.compile(r"\b(?:no significant differen\w+|significantly (?:reduc\w+|increas\w+|decreas\w+)|median (?:mean |maximum )?(?:heart |lung |organ )?dose)\b", re.I)
ENDPOINT = re.compile(r"\b(?:clonogenic|radiosensitiv\w*|radiosensiti[sz]\w*|radioresistan\w*|dna damage|cell viabilit\w*|apoptosis|cell survival)\b", re.I)
DOSE = re.compile(r"\d\s*(?:c?gy|rbe)\b", re.I)
TOXICITY = re.compile(r"\b(?:toxicit\w+|adverse events?|mucositis|esophagitis|pneumonitis)\b", re.I)
DESIGN = re.compile(r"\b(?:patients? (?:with|were|received)|cohort|case series|retrospectiv\w+|prospectiv\w+)\b", re.I)


def reads():
    blocks = defaultdict(lambda: defaultdict(list))
    for row in csv_rows(SOURCE):
        if row["pmid"].isascii() and row["pmid"].isdigit() and row["text"].strip():
            blocks[row["pmid"]][row["block_type"]].append(row)
    # Restrict the frame to one complete, unambiguous title/abstract pair per PMID.
    pairs = {
        pmid: [sections["title"][0], sections["abstract"][0]]
        for pmid, sections in blocks.items()
        if len(sections["title"]) == len(sections["abstract"]) == 1
    }
    prior = {
        case["pmid"] for name in ("benchmark", "holdout")
        for case in json.loads((ROOT / f"RadBioNET_model_{name}_cases.json").read_text())["cases"]
    }
    return pairs, prior


def prescreen(title, abstract):
    text = f"{title}\n{abstract}"
    if not RADIATION.search(text):
        return
    if ROLE.search(text) and MOLECULAR.search(text) and ENDPOINT.search(text):
        yield "factor_role"
    if OUTCOME.search(abstract) and (ENDPOINT.search(text) or TOXICITY.search(text) or DOSE.search(text)):
        yield "outcome"
    for beam, pattern in BEAMS.items():
        if pattern.search(text) and DOSE.search(abstract):
            yield beam
    if (BEAMS["proton"].search(text) or BEAMS["carbon_ion"].search(text)) and not DOSE.search(text):
        yield "unsupported_dose"
    if BEAMS["proton"].search(text) and DESIGN.search(abstract) and TOXICITY.search(abstract):
        yield "unsupported_comparison"


def screen(pairs, prior):
    pools = defaultdict(list)
    for pmid in sorted(pairs, key=int):
        if pmid in prior:
            continue
        title, abstract = (block["text"] for block in pairs[pmid])
        for pool in prescreen(title, abstract):
            pools[pool].append(pmid)
    rng = random.Random(SEED)
    draws = []
    for split, quotas in DRAWS.items():
        for pool in quotas:
            permutation = rng.sample(pools[pool], k=len(pools[pool]))
            for position, pmid in enumerate(permutation, 1):
                draws.append({"split": split, "pool": pool, "rank": position, "pmid": pmid})
    path = OUTPUT / "sampling_manifest.json"
    manifest = {
        "seed": SEED, "python_version": sys.version.split()[0], "source": str(SOURCE),
        "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "unique_title_abstract_pairs": len(pairs), "excluded_pilot_pmids": sorted(prior, key=int),
        "prescreen_frame": len(set(pairs) - prior), "pool_sizes": {k: len(v) for k, v in pools.items()},
        "quotas": DRAWS, "pool_order": list(DRAWS["selection"]), "split_order": list(DRAWS),
    }
    write_json(path, manifest)
    write_csv(OUTPUT / "candidate_draw_order.csv", ("split", "pool", "rank", "pmid"), draws)
    return draws


def freeze(draws, pairs):
    decisions = json.loads((OUTPUT / "screening_and_reference.json").read_text())
    review = {(row["split"], row["pool"], row["pmid"]): row for row in decisions}
    if len(review) != len(decisions):
        raise ValueError("Duplicate adjudication for a sampled position.")
    used_pmids = set()
    consumed = set()
    references = defaultdict(list)
    flow = []
    for split, quotas in DRAWS.items():
        for pool, quota in quotas.items():
            accepted = 0
            for row in draws:
                if (row["split"], row["pool"]) != (split, pool):
                    continue
                pmid = row["pmid"]
                key = split, pool, pmid
                if pmid in used_pmids:
                    flow.append(dict(row, decision="duplicate", rationale="PMID already accepted"))
                    continue
                decision = review[key]
                consumed.add(key)
                if "reject" in decision:
                    flow.append(dict(row, decision="excluded", rationale=decision["reject"]))
                    continue
                task = "irradiation_arm" if pool in BEAMS else "unsupported" if pool.startswith("unsupported") else pool
                expected = decision["expected"]
                if bool(expected) == (task == "unsupported"):
                    raise ValueError(f"Expected findings are inconsistent with the pool: {key}")
                for finding in expected:
                    if not finding["evidence_terms"] or not set(finding).issubset(
                        {"factor", "role", "beam", "dose", "dose_role", "comparator", "endpoint", "direction", "evidence_terms"}
                    ):
                        raise ValueError(f"Invalid reference annotation: {key}")
                blocks = [{"block_id": block["block_id"], "label": block["block_type"],
                           "sha256": block["text_sha256"]} for block in pairs[pmid]]
                references[split].append({"case_id": f"{task}_{pmid}", "pmid": pmid, "task_type": task,
                                          "sampling_pool": pool, "draw_rank": row["rank"], "source_blocks": blocks,
                                          "focus": decision["focus"], "expected": expected})
                used_pmids.add(pmid)
                flow.append(dict(row, decision="included", rationale=decision.get("eligibility", "")))
                accepted += 1
                if accepted == quota:
                    break
            if accepted != quota:
                raise ValueError(f"Insufficient eligible candidates for {split}/{pool}")
    assert consumed == set(review), "Screening ledger includes decisions outside the consumed prefix."
    write_csv(OUTPUT / "screening_flow.csv", ("split", "pool", "rank", "pmid", "decision", "rationale"), flow)
    _, _, schema = extraction_profile("clarified")
    for split, cases in references.items():
        target = OUTPUT / f"{split}_reference.json"
        write_json(target, {"benchmark_version": f"radbionet-random-{SEED}-{split}-1",
                            "reference_status": "AI-assisted abstract annotation before model inference. Independent expert verification pending.",
                            "cases": cases})
        _, verified = load_cases(target, SOURCE, schema)
        for case in verified:
            for fact in case["expected"]:
                dose = fact.get("dose")
                if dose and normalize(dose) not in normalize(case["corpus"]):
                    raise ValueError(f"Reference dose missing from {case['case_id']}")
        print(split, len(cases), "tasks", sum(len(c["expected"]) for c in cases), "findings")
    print(dict(Counter(row["decision"] for row in flow)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--screen", action="store_true")
    modes.add_argument("--freeze", action="store_true")
    parser.add_argument("--peek", type=int, default=0,
                        help="print each pool's first candidates for source verification")
    args = parser.parse_args()
    pairs, prior = reads()
    if args.screen:
        draws = screen(pairs, prior)
        if args.peek:
            for row in draws:
                if row["rank"] <= args.peek:
                    title = pairs[row["pmid"]][0]["text"]
                    print(row["split"], row["pool"], row["rank"], row["pmid"], title)
    else:
        draws = list(csv_rows(OUTPUT / "candidate_draw_order.csv"))
        freeze(draws, pairs)
