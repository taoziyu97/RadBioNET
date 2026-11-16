"""Calculate design-based correctness from a completed independent relation audit."""
import argparse
from collections import defaultdict
import json
from math import lgamma, exp, sqrt
from pathlib import Path
from statistics import NormalDist

from .adjudicate import read_csv
from .build import digest


def log_choose(n, k):
    return lgamma(n + 1) - lgamma(k + 1) - lgamma(n - k + 1)


def exact_bounds(population, draws, correct, alpha):
    def probability(total, lower, upper):
        lower = max(lower, draws - population + total, 0)
        upper = min(upper, total, draws)
        denom = log_choose(population, draws)
        return sum(exp(log_choose(total, x) + log_choose(population - total, draws - x) - denom)
                   for x in range(lower, upper + 1))

    low, high = correct, population - draws + correct
    while low < high:
        middle = (low + high) // 2
        if probability(middle, correct, draws) >= alpha / 2:
            high = middle
        else:
            low = middle + 1
    lower = low
    low, high = correct, population - draws + correct
    while low < high:
        middle = (low + high + 1) // 2
        if probability(middle, 0, correct) >= alpha / 2:
            low = middle
        else:
            high = middle - 1
    return lower / population, low / population


def weighted_estimate(strata, unverifiable_is_correct, alpha=0.05):
    total = sum(N for N, _ in strata)
    mean, variance = 0.0, 0.0
    boundary = False
    for N, results in strata:
        n = len(results)
        x = results.count("correct") + unverifiable_is_correct * results.count("unverifiable")
        weight, p = N / total, x / n
        mean += weight * p
        if n < N:
            if n < 2 or x in {0, n}:
                boundary = True
            else:
                variance += weight**2 * (1 - n / N) * p * (1 - p) / (n - 1)
    if boundary:
        lo, hi = 0.0, 0.0
        for N, results in strata:
            x = results.count("correct") + unverifiable_is_correct * results.count("unverifiable")
            low, high = exact_bounds(N, len(results), x, alpha / len(strata))
            lo += N / total * low
            hi += N / total * high
        method = "weighted_simultaneous_exact_hypergeometric"
    else:
        margin = NormalDist().inv_cdf(1 - alpha / 2) * sqrt(variance)
        lo, hi = max(0, mean - margin), min(1, mean + margin)
        method = "stratified_normal_finite_population"
    return dict(estimate=mean, confidence_interval=[lo, hi], method=method)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sample", required=True, type=Path)
    parser.add_argument("--audit", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    sample = read_csv(args.sample)
    if not sample:
        parser.error("The accepted-relation audit sample is empty.")
    sample_ids = {row["relation_id"] for row in sample}
    audited = {}
    for row in read_csv(args.audit):
        if not row.get("result"):
            continue
        rid = row["relation_id"]
        if rid in audited or rid not in sample_ids:
            raise ValueError(f"Duplicate or unexpected audit ID: {rid}")
        if row["result"] not in {"correct", "incorrect", "unverifiable"} or not row["auditor_id"] or not row["reason"]:
            raise ValueError(f"Incomplete audit decision for {rid}")
        audited[rid] = row["result"]
    if audited.keys() != sample_ids:
        raise ValueError("Complete every selected audit record before estimating correctness.")
    groups = defaultdict(list)
    for row in sample:
        groups[(row["source_membership"], row["particle"])].append(row)
    strata = []
    for rows in groups.values():
        n = len(rows)
        N = int(rows[0]["population_size"])
        if n > N or any(int(row["sample_size"]) != n or int(row["population_size"]) != N
                        or abs(float(row["inclusion_probability"]) - n / N) > 1e-10 for row in rows):
            raise ValueError("Inconsistent audit sampling frame")
        strata.append((N, [audited[row["relation_id"]] for row in rows]))
    total = sum(N for N, _ in strata)
    result = dict(sample_size=len(sample), population=total, strata=len(strata),
                  sample_sha256=digest(args.sample), audit_sha256=digest(args.audit),
                  unverifiable_share=sum(N / total * rows.count("unverifiable") / len(rows)
                                         for N, rows in strata),
                  unverifiable_as_incorrect=weighted_estimate(strata, False),
                  unverifiable_as_correct=weighted_estimate(strata, True))
    with args.output.open("x") as fh:
        json.dump(result, fh, indent=2)
        fh.write("\n")


if __name__ == "__main__":
    main()
