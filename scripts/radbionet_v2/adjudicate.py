"""Check completed review forms and export source-grounded adjudicated relations."""
import argparse
from collections import Counter, defaultdict
import csv
import json
from fractions import Fraction
import random
from pathlib import Path
import tempfile

from .build import digest, stable_id, write_csv

DECISIONS = {"accept", "exclude", "uncertain"}
SCREEN_DECISIONS = {"include", "exclude", "uncertain"}
RELATION_FIELDS = ("factor_role", "perturbation", "comparison", "outcome", "time_point",
                   "effect_direction", "evidence_locator")
ARM_FIELDS = ("experiment_key", "index_arm", "reference_arm", "particle_confirmed", "exposure_locator")


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return [{key: (value or "").strip() for key, value in row.items()}
                for row in csv.DictReader(stream)]


def decisions(paths, keys, allowed, registered, accept_fields=()):
    index = defaultdict(dict)
    for path in paths:
        for row in read_csv(path):
            if not row.get("decision"):
                continue
            key = tuple(row.get(field, "") for field in keys)
            if keys[-1] == "finding_key":
                if not key[-1]:
                    raise ValueError(f"{path.name}: missing finding_key for {key[0]}")
                known = key[:1] in registered
            else:
                known = key in registered
            reviewer = row.get("reviewer_id", "")
            if not known or not reviewer or row["decision"] not in allowed:
                raise ValueError(f"{path.name}: invalid review record {key}")
            if not row.get("reason") or not row.get("codebook_version"):
                raise ValueError(f"{path.name}: missing reason or codebook version for {key}")
            if row["decision"] == "accept" and any(not row.get(f) for f in accept_fields):
                raise ValueError(f"{path.name}: incomplete accepted relation for {key}")
            if row.get("particle_confirmed") and not all(
                    row.get(f) for f in ("experiment_key", "index_arm", "exposure_locator")):
                raise ValueError(f"{path.name}: confirmed particle requires experiment, arm and locator for {key}")
            if reviewer in index[key]:
                raise ValueError(f"{path.name}: duplicate decision by {reviewer} for {key}")
            index[key][reviewer] = row
    return index


def adjudicated(key, by_reviewer, adjudicators, compare):
    if len(by_reviewer) < 2:
        return None, "pending_second_review"
    if len(by_reviewer) != 2:
        raise ValueError(f"Exactly two independent decisions are expected for {key}")
    a, b = by_reviewer.values()
    if a["codebook_version"] != b["codebook_version"]:
        return None, "codebook_mismatch"
    final = adjudicators.get(key, {})
    if len(final) > 1:
        raise ValueError(f"More than one adjudication for {key}")
    if final:
        reviewer, row = next(iter(final.items()))
        if reviewer in by_reviewer or row["codebook_version"] != a["codebook_version"]:
            raise ValueError(f"Invalid adjudicator or codebook for {key}")
        return row, "adjudicated"
    if all(a.get(field, "") == b.get(field, "") for field in compare):
        return a, "independent_agreement"
    return None, "awaiting_adjudication"


def audit_sample(records, publications, seed, target):
    strata = defaultdict(list)
    for row in records:
        pub = publications[row["publication_id"]]
        key = (pub["source_membership"], row["particle_confirmed"] or "unresolved")
        strata[key].append(row)
    sizes = {key: len(group) for key, group in strata.items()}
    allocation = {key: min(2, size) for key, size in sizes.items()}
    target = min(len(records), max(target, sum(allocation.values())))
    while sum(allocation.values()) < target:
        # Allocate remaining slots to the largest deficit from proportional allocation.
        eligible = (key for key in sorted(sizes) if allocation[key] < sizes[key])
        key = max(eligible, key=lambda k: Fraction(target * sizes[k], len(records)) - allocation[k])
        allocation[key] += 1
    rng = random.Random(seed)
    for key in sorted(strata):
        n = allocation[key]
        group = sorted(strata[key], key=lambda row: row["relation_id"])
        for row in rng.sample(group, n):
            yield dict(relation_id=row["relation_id"], publication_id=row["publication_id"],
                       source_membership=key[0], particle=key[1], population_size=sizes[key],
                       sample_size=n, inclusion_probability=n / sizes[key], seed=seed)


def run(args, folder):
    source = args.prepared
    manifest = json.loads((source / "checksums.json").read_text())
    for name, sha in manifest.items():
        if digest(source / name) != sha:
            raise ValueError(f"Prepared input checksum mismatch: {name}")
    candidates = {r["candidate_id"]: r for r in read_csv(source / "candidates.csv")}
    pubs = {r["publication_id"]: r for r in read_csv(source / "publications.csv")}
    screen_keys = {(pub, stage) for pub in pubs for stage in ("title_abstract", "full_text")}
    candidates_keys = {(key,) for key in candidates}
    screening = decisions(args.screening, ("publication_id", "stage"), SCREEN_DECISIONS, screen_keys)
    screen_final = decisions(args.screening_adjudication, ("publication_id", "stage"),
                             SCREEN_DECISIONS, screen_keys)
    review = decisions(args.reviews, ("candidate_id", "finding_key"), DECISIONS, candidates_keys, RELATION_FIELDS)
    review_final = decisions(args.adjudication, ("candidate_id", "finding_key"), DECISIONS, candidates_keys,
                             RELATION_FIELDS)
    screen_status, reports = {}, []
    for pub in sorted(pubs):
        if pubs[pub]["screening_status"] == "retracted":
            screen_status[pub] = "blocked_retracted"
        else:
            keys = [(pub, stage) for stage in ("title_abstract", "full_text")]
            first, first_state = adjudicated(keys[0], screening.get(keys[0], {}), screen_final, ("decision",))
            if keys[1] in screening:
                final, state = adjudicated(keys[1], screening[keys[1]], screen_final, ("decision",))
                screen_status[pub] = final["decision"] if final else state
            else:
                screen_status[pub] = ("requires_full_text" if first and first["decision"] == "uncertain"
                                      else first["decision"] if first else first_state)
        reports.append(dict(publication_id=pub, status=screen_status[pub]))
    outcomes, released, arms, logical_keys = [], [], {}, {}
    findings = defaultdict(set)
    for cid, finding_key in set(review) | set(review_final):
        findings[cid].add(finding_key)
    for cid, finding in sorted((cid, finding) for cid in candidates
                               for finding in findings.get(cid, {"1"})):
        candidate = candidates[cid]
        key = (cid, finding)
        final, status = adjudicated(key, review.get(key, {}), review_final,
                                    ("decision", *RELATION_FIELDS, *ARM_FIELDS))
        pub = candidate["publication_id"]
        if candidate["relation_status"] == "blocked_retracted":
            status = "blocked_retracted"
        elif final and final["decision"] == "accept" and screen_status[pub] != "include":
            status = "screening_" + screen_status[pub]
        elif final and final["decision"] == "accept":
            relation_id = stable_id("relation", cid, finding)
            experiment_id = stable_id("experiment", pub, final["experiment_key"]) if final.get("experiment_key") else ""
            arm_id = ""
            if experiment_id and final.get("index_arm"):
                arm_id = stable_id("arm", experiment_id, final["index_arm"])
                arm = dict(arm_id=arm_id, experiment_id=experiment_id, publication_id=pub,
                           arm_label=final["index_arm"], particle=final.get("particle_confirmed", ""),
                           exposure_locator=final.get("exposure_locator", ""))
                old = arms.get(arm_id)
                if old and old["particle"] and arm["particle"] and old["particle"] != arm["particle"]:
                    raise ValueError(f"Conflicting confirmed particles for arm {arm_id}")
                if not old or not old["particle"]:
                    arms[arm_id] = arm
            logical_key = (pub, experiment_id, arm_id, candidate["factor_legacy_label"].casefold(),
                           *(final.get(field, "").casefold() for field in
                             ("reference_arm", "factor_role", "perturbation", "comparison",
                              "outcome", "time_point", "effect_direction")))
            if logical_key in logical_keys:
                raise ValueError(f"Duplicate reviewed finding: {key} and {logical_keys[logical_key]}")
            logical_keys[logical_key] = key
            released.append(dict(relation_id=relation_id, candidate_id=cid, finding_key=finding,
                                 publication_id=pub, experiment_id=experiment_id, arm_id=arm_id,
                                 factor_label=candidate["factor_legacy_label"],
                                 particle_attribution="source_confirmed" if final.get("particle_confirmed") else "unresolved",
                                 decision_basis=status, codebook_version=final["codebook_version"],
                                 **{name: final.get(name, "") for name in RELATION_FIELDS + ARM_FIELDS}))
            status = "accepted"
        elif final:
            status = final["decision"]
        outcomes.append(dict(candidate_id=cid, finding_key=finding, status=status,
                             independent_reviews=len(review.get(key, {}))))
    write_csv(folder, "publication_decisions", "publication_id status", reports)
    write_csv(folder, "candidate_decisions", "candidate_id finding_key status independent_reviews", outcomes)
    write_csv(folder, "accepted_relations",
              "relation_id candidate_id finding_key publication_id experiment_id arm_id factor_label particle_attribution decision_basis codebook_version " +
              " ".join(RELATION_FIELDS + ARM_FIELDS), released)
    write_csv(folder, "irradiation_arms", "arm_id experiment_id publication_id arm_label particle exposure_locator",
              (arms[aid] for aid in sorted(arms)))
    write_csv(folder, "annotation_decisions",
              "candidate_id finding_key reviewer_id decision reason codebook_version decision_stage " +
              " ".join(RELATION_FIELDS + ARM_FIELDS),
              (dict(candidate_id=key[0], finding_key=key[1], reviewer_id=reviewer,
                    decision=row["decision"], reason=row["reason"],
                    codebook_version=row["codebook_version"], decision_stage=stage,
                    **{field: row.get(field, "") for field in RELATION_FIELDS + ARM_FIELDS})
               for stage, entries in [("independent", review), ("adjudication", review_final)]
               for key, decisions_for_key in sorted(entries.items())
               for reviewer, row in sorted(decisions_for_key.items())))
    sample = list(audit_sample(released, pubs, args.seed, 400))
    write_csv(folder, "audit_sample",
              "relation_id publication_id source_membership particle population_size sample_size inclusion_probability seed", sample)
    write_csv(folder, "audit_form", "relation_id auditor_id result evidence_locator reason",
              (dict(relation_id=row["relation_id"]) for row in sample))
    write_csv(folder, "screening_decisions",
              "publication_id stage reviewer_id decision reason evidence_locator codebook_version decision_stage",
              (dict(publication_id=key[0], stage=key[1], reviewer_id=reviewer, decision=row["decision"],
                    reason=row["reason"], evidence_locator=row.get("evidence_locator", ""),
                    codebook_version=row["codebook_version"], decision_stage=stage)
               for stage, entries in [("independent", screening), ("adjudication", screen_final)]
               for key, by_reviewer in sorted(entries.items())
               for reviewer, row in sorted(by_reviewer.items())))
    result = dict(accepted_relations=len(released), audit_sample_size=len(sample),
                  candidate_status_counts=dict(sorted(Counter(row["status"] for row in outcomes).items())),
                  reviewed_candidates=len({key[0] for key in review}),
                  screened_publications=len({key[0] for key in screening}),
                  candidate_source_sha256=digest(source / "checksums.json"),
                  review_inputs=[dict(file=path.name, sha256=digest(path))
                                 for path in args.screening + args.screening_adjudication +
                                 args.reviews + args.adjudication])
    (folder / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prepared", required=True, type=Path)
    parser.add_argument("--screening", action="append", default=[], type=Path)
    parser.add_argument("--screening-adjudication", action="append", default=[], type=Path)
    parser.add_argument("--reviews", action="append", default=[], type=Path)
    parser.add_argument("--adjudication", action="append", default=[], type=Path)
    parser.add_argument("--seed", type=int, default=20261113)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output already exists. Use a new versioned directory.")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".radbionet-", dir=args.output.parent) as temp:
        folder = Path(temp) / "build"
        folder.mkdir()
        run(args, folder)
        folder.rename(args.output)


if __name__ == "__main__":
    main()
