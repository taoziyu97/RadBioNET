"""Reconcile the legacy workbook and source records into a reviewable RadBioNET dataset."""
import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import random
import re
import tempfile
import platform
import unicodedata

from openpyxl import __version__ as openpyxl_version, load_workbook

from .dose import NUMBER, UNIT, parse_dose
from .pubmed import parse_articles

PATTERN_FILE = Path(__file__).with_name("legacy_patterns.json")
CASES = Path(__file__).with_name("source_checks.csv")
TAG = re.compile(r"^([A-Z0-9]{2,4})\s*- (.*)$")
NOTICE_TYPES = {"retracted publication", "retraction of publication", "published erratum",
                "expression of concern", "corrected and republished article"}
DOSE_SIGNAL = re.compile(r"\b(?:c?gy)\b", re.I)
DOSE_IN_TEXT = re.compile(
    rf"(?<![\w.+−-])(?:"
    rf"(?:total(?:\s+dose)?(?:\s+of)?\s+)?{NUMBER}\s*{UNIT}\s*(?:in|over|/)\s*\d+\s*(?:equal\s*)?fractions?"
    rf"|\d+\s*(?:[×xX*]|fractions?\s+of)\s*{NUMBER}\s*{UNIT}"
    rf"|{NUMBER}(?:\s*,\s*{NUMBER})*\s*,?\s*(?:or|and)\s*{NUMBER}\s*{UNIT}"
    rf"|{NUMBER}(?:\s*,\s*{NUMBER})+\s*{UNIT}"
    rf"|{NUMBER}(?:\s*[-–−]\s*{NUMBER})?\s*{UNIT}(?:\s*[×xX*]\s*\d+|\s*per fraction)?"
    rf")(?!\w|\s*/\s*(?:min|s|h)\b)", re.I)
SENTENCE_END = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9(])")
ABBREVIATION = re.compile(r"\b(?:e\.g|i\.e|et al|Fig|Dr|vs|No|Vol|Inc)\.$", re.I)
MISSING = {"", "unspecified", "(none)", "(unknown)", "unknown", "not reported"}


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def stable_id(prefix, *parts):
    key = json.dumps(parts, ensure_ascii=False, separators=(",", ":"))
    return f"{prefix}:{hashlib.sha256(key.encode()).hexdigest()[:24]}"


def clean(value):
    return "" if value is None else str(value).strip()


def doi_key(value):
    return re.sub(r"^(?:https?://(?:dx\.)?doi\.org/|doi:\s*)", "", clean(value), flags=re.I).lower()


def title_key(value):
    return " ".join(unicodedata.normalize("NFKC", clean(value)).casefold().split()).rstrip(".")


def split_labels(value):
    return list(dict.fromkeys(x.strip() for x in clean(value).split(";") if x.strip()))


def first(record, key):
    return next(iter(record.get(key, [])), "")


def nbib_records(path):
    with path.open(encoding="utf-8-sig") as stream:
        fields = {}
        tag = ""
        for line in stream:
            line = line.rstrip("\r\n")
            match = TAG.match(line)
            if match:
                tag, value = match.groups()
                if tag == "PMID" and fields:
                    yield fields
                    fields = {}
                fields.setdefault(tag, []).append(value.strip())
            elif tag and line.startswith("      "):
                fields[tag][-1] += " " + line.strip()
        if fields:
            yield fields


def xlsx_rows(path, sheet=None):
    book = load_workbook(path, read_only=True, data_only=True)
    try:
        values = iter((book[sheet] if sheet else book.worksheets[0]).values)
        headers = next(values)
        if len(headers) != len(set(headers)) or None in headers:
            raise ValueError(f"Duplicate or empty columns in {path}")
        for number, row in enumerate(values, 2):
            yield number, dict(zip(headers, (clean(x) for x in row)))
    finally:
        book.close()


def span_list(text):
    start = 0
    for m in SENTENCE_END.finditer(text):
        if not ABBREVIATION.search(text[max(start, m.start() - 15):m.start()]):
            yield start, m.start()
            start = m.end()
    if start < len(text):
        yield start, len(text)


def evidence_blocks(publication_id, pmid, variants):
    for block_kind, tag in [("title", "TI"), ("abstract", "AB")]:
        seen = set()
        for _, record, source_id in variants:
            for block in record.get(tag, []):
                if not block or block in seen:
                    continue
                seen.add(block)
                block_id = stable_id("block", publication_id, block_kind, block)
                yield dict(block_id=block_id, publication_id=publication_id, pmid=pmid,
                           source_id=source_id, block_type=block_kind,
                           text_sha256=hashlib.sha256(block.encode()).hexdigest(), text=block)


def setup_inputs(args):
    variants = defaultdict(list)
    manifest, sources, runs = [], [], []
    sources_seen = set()

    def add_input(path, role):
        key = digest(path)
        file_id = stable_id("input", role, path.name, key)
        manifest.append(dict(input_id=file_id, role=role, file=path.name,
                             sha256=key, bytes=path.stat().st_size))
        return file_id, key

    for stream, paths in [("general", args.general), ("proton", args.proton)]:
        for path in sorted(paths):
            file_id, _ = add_input(path, f"archived_{stream}")
            count = 0
            pmids = set()
            for record in nbib_records(path):
                pmid = first(record, "PMID")
                if not pmid.isdigit():
                    raise ValueError(f"Invalid PMID in {path}")
                count += 1
                pmids.add(pmid)
                if (pmid, file_id) not in sources_seen:
                    variants[pmid].append((0, record, file_id))
                    sources_seen.add((pmid, file_id))
            runs.append(dict(source_id=file_id, stream=stream, capture="historical_nbib",
                             file=path.name, records=count, unique_pmids=len(pmids)))
            sources.extend(dict(publication_id=f"pmid:{pmid}", source_id=file_id, stream=stream,
                                capture="historical_nbib") for pmid in sorted(pmids, key=int))
    for folder in sorted(args.capture):
        captured = json.loads((folder / "manifest.json").read_text())
        capture_id, _ = add_input(folder / "manifest.json", "capture_manifest")
        for name, sha in captured["files"].items():
            if digest(folder / name) != sha:
                raise ValueError(f"Capture checksum mismatch: {folder / name}")
        captured_pmids = set()
        with (folder / "memberships.csv").open(newline="") as stream:
            memberships = list(csv.DictReader(stream))
        for file in sorted(folder.glob("efetch_*.xml")):
            file_id, _ = add_input(file, "capture_xml")
            for record in parse_articles(file):
                pmid = first(record, "PMID")
                if pmid in captured_pmids:
                    raise ValueError(f"Duplicate captured PMID: {pmid}")
                captured_pmids.add(pmid)
                variants[pmid].append((1, record, file_id))
        if captured_pmids != {row["pmid"] for row in memberships}:
            raise ValueError(f"Capture membership mismatch: {folder}")
        sources.extend(dict(publication_id=f"pmid:{row['pmid']}", source_id=capture_id,
                            stream=row["stream"], capture=captured["mode"]) for row in memberships)
        for run in captured["runs"]:
            runs.append(dict(source_id=capture_id, stream=run["stream"], capture=captured["mode"],
                             file=run["raw"], records=run["count"], unique_pmids=run["returned"],
                             query=run["query"], translation=run["translation"],
                             start=run["start"], end=run["end"], started_utc=captured["started_utc"],
                             terminal=run["terminal"], warnings=json.dumps(run.get("warnings", {}))))
    return variants, sources, runs, manifest, add_input


def index_publications(variants, sources):
    pubs, dois, titles, blocks = {}, defaultdict(set), defaultdict(set), {}
    source_memberships = defaultdict(set)
    for row in sources:
        source_memberships[row["publication_id"]].add(f"{row['capture']}:{row['stream']}")
    for pmid, items in sorted(variants.items(), key=lambda x: int(x[0])):
        publication_id = f"pmid:{pmid}"
        items.sort(key=lambda entry: (-entry[0], -len(first(entry[1], "AB")), entry[2]))
        _, record, source_id = items[0]
        doi_values = set()
        for _, version, _ in items:
            if title_key(first(version, "TI")):
                titles[title_key(first(version, "TI"))].add(publication_id)
            for item in version.get("AID", []) + version.get("LID", []):
                if item.lower().endswith(" [doi]"):
                    doi = doi_key(item[:-6])
                    if doi:
                        dois[doi].add(publication_id)
                        doi_values.add(doi)
        types = sorted({pt for _, version, _ in items for pt in version.get("PT", [])})
        notices = sorted({val for _, version, _ in items
                          for k in ("RIN", "ROF", "EFR", "EIN", "UIN", "UOF") for val in version.get(k, [])})
        retracted = any(pt.lower() == "retracted publication" for pt in types) or any(
            val.startswith("RetractionIn:") for val in notices)
        status = ("retracted" if retracted else "notice_review" if notices or
                  any(pt.lower() in NOTICE_TYPES for pt in types) else "pending")
        pubs[publication_id] = dict(publication_id=publication_id, pmid=pmid,
                                    doi="|".join(sorted(doi_values)), title=first(record, "TI"),
                                    publication_date=first(record, "DP"), journal=first(record, "JT"),
                                    language="|".join(sorted(set(record.get("LA", [])))),
                                    publication_types="|".join(types), notice_links="|".join(notices),
                                    source_membership="|".join(sorted(source_memberships[publication_id])),
                                    preferred_source_id=source_id, screening_status=status,
                                    url=f"https://pubmed.ncbi.nlm.nih.gov/{pmid}/")
        blocks[publication_id] = list(evidence_blocks(publication_id, pmid, items))
    return pubs, dois, titles, blocks


def resolve(row, dois, titles, pubs):
    supplied = clean(row.get("PMID"))
    doc_doi = doi_key(row.get("DOI"))
    by_doi = dois.get(doc_doi, set())
    by_title = titles.get(title_key(row["Title"]), set())
    by_pmid = f"pmid:{supplied}" if supplied.isdigit() else ""
    if by_pmid in pubs:
        if by_doi and by_pmid not in by_doi:
            return "", "conflicting_ids"
        return by_pmid, "archived_pmid"
    if len(by_doi) == 1:
        found = next(iter(by_doi))
        if by_title and found not in by_title:
            return "", "conflicting_doi_title"
        return found, "unique_doi"
    if len(by_doi) > 1:
        intersection = by_doi & by_title
        if len(intersection) == 1:
            return next(iter(intersection)), "doi_title_disambiguated"
        return "", "ambiguous_doi"
    if not doc_doi and len(by_title) == 1:
        found = next(iter(by_title))
        year = row.get("Publication year", "")
        if year and year not in pubs[found]["publication_date"]:
            return "", "title_year_conflict"
        return found, "unique_title_year_checked"
    return "", "ambiguous_title" if len(by_title) > 1 else "unmatched"


def pattern_candidates(publication_id, blocks, patterns):
    factors, directions = patterns
    found = []
    for block in blocks:
        if block["block_type"] != "abstract":
            continue
        txt = block["text"]
        relevant_directions = [(label, pattern) for label, pattern in directions if pattern.search(txt)]
        if not relevant_directions:
            continue
        relevant_factors = [(label, pattern) for label, pattern in factors if pattern.search(txt)]
        if not relevant_factors:
            continue
        spans = list(span_list(txt))
        for idx, (begin, end) in enumerate(spans):
            window_start = spans[max(0, idx - 1)][0]
            window_end = spans[min(len(spans) - 1, idx + 1)][1]
            for factor, pattern in relevant_factors:
                mention = pattern.search(txt, begin, end)
                if not mention:
                    continue
                for direction, regex in relevant_directions:
                    trigger = regex.search(txt, begin, end) or regex.search(txt, window_start, window_end)
                    if not trigger:
                        continue
                    start, stop = begin, end
                    if trigger.start() < begin:
                        start = window_start
                    elif trigger.end() > end:
                        stop = window_end
                    found.append((factor, direction, "", block["block_id"], start, stop,
                                  txt[start:stop], "same_sentence" if begin <= trigger.start() < end else
                                  "adjacent_sentence", mention.group(), trigger.group()))
    return found


def load_patterns():
    patterns = json.loads(PATTERN_FILE.read_text())
    factors = [(label, re.compile("|".join(f"(?:{expr})" for expr, _ in pairs), re.I))
               for label, pairs in patterns["factors"].items()]
    directions = [(label, re.compile("|".join(f"(?:{expr})" for expr in expressions), re.I))
                  for label, expressions in patterns["directions"].items()]
    return factors, directions


def build(args, folder):
    variants, sources, runs, manifest, add_input = setup_inputs(args)
    pubs, dois, titles, blocks = index_publications(variants, sources)
    workbook_id, workbook_sha = add_input(args.workbook, "legacy_workbook")
    add_input(PATTERN_FILE, "candidate_patterns")
    add_input(CASES, "targeted_source_checks")
    candidates, evidence, crosswalk, legacy, doses, dose_links = {}, {}, [], [], {}, set()
    candidate_sources, issues, dose_cases = set(), set(), []
    for code_file in [Path(__file__), Path(__file__).with_name("pubmed.py"),
                      Path(__file__).with_name("dose.py")]:
        add_input(code_file, "processing_code")
    audit_index = defaultdict(list)
    audit_candidates = []

    def candidate(pub, factor, direction, particle, origin):
        candidate_id = stable_id("candidate", pub, factor, direction, particle)
        candidates.setdefault(candidate_id, dict(candidate_id=candidate_id, publication_id=pub,
                              pmid=pubs[pub]["pmid"], factor_legacy_label=factor,
                              direction_candidate=direction, particle_candidate=particle,
                              relation_status="pending_review", arm_id=""))
        candidate_sources.add((candidate_id, origin))
        return candidate_id

    def support(cid, block_id, begin, end, locator, excerpt, mode, mention="", trigger=""):
        key = stable_id("evidence", cid, block_id, begin, end, locator, excerpt)
        evidence[key] = dict(evidence_id=key, candidate_id=cid, block_id=block_id, start=begin,
                             end=end, source_locator=locator, evidence_scope=mode, excerpt=excerpt,
                             factor_match=mention, direction_match=trigger)

    def locate(text, pub):
        matches = [(block["block_id"], match.start())
                   for block in blocks.get(pub, []) if text
                   for match in re.finditer(re.escape(text), block["text"])]
        if len(matches) == 1:
            block_id, begin = matches[0]
            return block_id, begin, begin + len(text)
        return "", None, None

    def add_dose(pub, raw, origin, block_id="", begin=None, end=None):
        parsed = parse_dose(raw)
        dose_id = stable_id("dose", pub, raw, block_id, begin)
        doses.setdefault(dose_id, dict(dose_id=dose_id, publication_id=pub, expression=raw,
                                       block_id=block_id, start=begin, end=end, arm_id="",
                                       arm_attribution="unresolved", origin=origin, **parsed))
        return dose_id

    if args.direction_audit:
        audit_id, _ = add_input(args.direction_audit, "historical_direction_audit")
        for row_num, row in xlsx_rows(args.direction_audit, "5_Per_direction_audit_v2"):
            pub, _ = resolve(row, dois, titles, pubs)
            if pub:
                for direction in split_labels(row["Direction"]):
                    key = (pub, row["Factor"], direction, row["Radiation particle category"])
                    audit_index[key].append((row_num, row))

    for row_num, row in xlsx_rows(args.workbook):
        legacy_id = f"legacy:{workbook_sha[:16]}:{row_num}"
        pub, method = resolve(row, dois, titles, pubs)
        if not pub:
            pub = stable_id("unresolved", workbook_id, row.get("DOI", ""), row["Title"])
            pubs.setdefault(pub, dict(publication_id=pub, pmid="", doi=doi_key(row.get("DOI")),
                                      title=row["Title"], screening_status="identity_review", url=""))
            issues.add(("legacy", legacy_id, "bibliography_" + method))
        labels = split_labels(row["Direction"])
        if row["Direction labels (n)"] and row["Direction labels (n)"] != str(len(labels)):
            issues.add(("legacy", legacy_id, "direction_count_mismatch"))
        particle = row["Radiation particle category"]
        if particle == "Proton" and re.search(r"x[- ]?ray|gamma", row["Particle type"], re.I):
            issues.add(("legacy", legacy_id, "particle_category_conflict"))
        if "Likely artifact" in row["Particle-specific verdict"]:
            issues.add(("legacy", legacy_id, "historical_likely_artifact"))
        legacy.append(dict(legacy_id=legacy_id, workbook_row=row_num, publication_id=pub,
                           resolved_pmid=pubs[pub]["pmid"], identity_method=method,
                           actual_direction_count=len(labels), **row))
        for direction in labels or [""]:
            cid = candidate(pub, row["Factor"], direction, particle, "legacy_workbook")
            crosswalk.append(dict(legacy_id=legacy_id, candidate_id=cid, disposition="pending_review"))
            matches = audit_index.get((pub, row["Factor"], direction, particle), [])
            if matches:
                for audit_row, entry in matches:
                    excerpt = entry["Supporting sentence"]
                    block_id, start, end = locate(excerpt, pub)
                    support(cid, block_id, start, end, f"{audit_id}:5_Per_direction_audit_v2:{audit_row}",
                            excerpt, "historical_per_direction")
                candidate_sources.add((cid, "historical_per_direction"))
            elif row["Supporting sentence"]:
                excerpt = row["Supporting sentence"]
                block_id, start, end = locate(excerpt, pub)
                support(cid, block_id, start, end, f"{workbook_id}:Sheet1:{row_num}", excerpt,
                        "legacy_collapsed_excerpt")
            if pubs[pub]["screening_status"] == "retracted":
                issues.add(("candidate", cid, "archived_retraction"))
        for raw in split_labels(row["Radiation dose"]):
            dose_id = add_dose(pub, raw, "legacy_document_context")
            dose_links.add((dose_id, legacy_id))
    # Recover candidates that were lost during the legacy direction collapse.
    for (pub, factor, direction, particle), items in sorted(audit_index.items()):
        cid = candidate(pub, factor, direction, particle, "historical_per_direction")
        for audit_row, row in items:
            excerpt = row["Supporting sentence"]
            block_id, start, end = locate(excerpt, pub)
            support(cid, block_id, start, end, f"{audit_id}:5_Per_direction_audit_v2:{audit_row}",
                    excerpt, "historical_per_direction")
        audit_candidates.append(cid)
    patterns = load_patterns()
    captured_pubs = {r["publication_id"] for r in sources if r["capture"] != "historical_nbib"}
    scan_pubs = set(blocks) if args.scan_archive else captured_pubs
    for pub in sorted(scan_pubs):
        for factor, direction, particle, block_id, start, end, excerpt, scope, mention, trigger in (
                pattern_candidates(pub, blocks[pub], patterns)):
            cid = candidate(pub, factor, direction, particle, "abstract_pattern")
            support(cid, block_id, start, end, block_id, excerpt, scope, mention, trigger)
    candidate_pubs = {r["publication_id"] for r in candidates.values()}
    for pub in sorted(candidate_pubs.intersection(blocks)):
        for block in blocks[pub]:
            if block["block_type"] != "abstract" or not DOSE_SIGNAL.search(block["text"]):
                continue
            for match in DOSE_IN_TEXT.finditer(block["text"]):
                add_dose(pub, match.group(), "abstract_dose_mention", block["block_id"],
                         match.start(), match.end())
    with CASES.open(newline="", encoding="utf-8") as file:
        for check in csv.DictReader(file):
            pub_ids = dois.get(check["doi"], set())
            if len(pub_ids) != 1:
                continue
            pub = next(iter(pub_ids))
            dose_cases.append(dict(publication_id=pub, **check))
            for cid, entry in candidates.items():
                if entry["publication_id"] != pub or not check["factor"]:
                    continue
                if entry["factor_legacy_label"].casefold() == check["factor"].casefold():
                    issues.add(("candidate", cid, check["finding"]))
    for check in dose_cases:
        if not check["reported_expression"]:
            continue
        pub = check["publication_id"]
        for raw in split_labels(check["reported_expression"]):
            dose_id = stable_id("dose", pub, raw, check["locator"], check["exposure"])
            parsed = parse_dose(raw)
            role = {"organ_dose_metric": "organ_metric",
                    "photon_fractionation_only": "fraction_schedule",
                    "proton_dose_conditions": "experimental_dose_conditions"}[check["finding"]]
            parsed["dose_role"] = role
            if role == "organ_metric":
                parsed.update(organ="heart", metric="mean",
                              summary_statistic="range" if parsed["parse_status"] == "range" else "median")
            doses[dose_id] = dict(dose_id=dose_id, publication_id=pub, expression=raw,
                                  block_id="", start=None, end=None, arm_id="",
                                  arm_attribution="exposure_context_verified",
                                  origin="targeted_source_check", **parsed)
            check.setdefault("dose_ids", []).append(dose_id)
        check["dose_ids"] = "|".join(check["dose_ids"])
    for cid, entry in candidates.items():
        if pubs[entry["publication_id"]]["screening_status"] == "retracted":
            entry["relation_status"] = "blocked_retracted"
    evidence_ids = defaultdict(list)
    for item in evidence.values():
        evidence_ids[item["candidate_id"]].append(item["evidence_id"])
    for cid, entry in candidates.items():
        entry["evidence_count"] = len(evidence_ids[cid])
    output_tables(args, folder, pubs, sources, runs, manifest, blocks, candidates, evidence,
                  crosswalk, legacy, doses, dose_links, issues, dose_cases, candidate_sources,
                  scan_pubs, audit_candidates)


def write_csv(folder, name, columns, rows):
    with (folder / f"{name}.csv").open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=columns.split(), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def output_tables(args, folder, pubs, sources, runs, manifest, blocks, candidates, evidence,
                  crosswalk, legacy, doses, dose_links, issues, dose_cases, candidate_sources,
                  scan_pubs, audit_candidates):
    fields = "publication_id pmid doi title publication_date journal language publication_types notice_links source_membership preferred_source_id screening_status url"
    write_csv(folder, "publications", fields, (pubs[key] for key in sorted(pubs)))
    write_csv(folder, "publication_sources", "publication_id source_id stream capture", sources)
    write_csv(folder, "search_runs", "source_id stream capture file records unique_pmids query translation start end started_utc terminal warnings", runs)
    write_csv(folder, "input_manifest", "input_id role file sha256 bytes", manifest)
    write_csv(folder, "candidates",
              "candidate_id publication_id pmid factor_legacy_label direction_candidate particle_candidate relation_status arm_id evidence_count",
              (candidates[key] for key in sorted(candidates)))
    write_csv(folder, "candidate_sources", "candidate_id origin",
              (dict(candidate_id=c, origin=o) for c, o in sorted(candidate_sources)))
    write_csv(folder, "legacy_crosswalk", "legacy_id candidate_id disposition", crosswalk)
    legacy_columns = list(legacy[0])
    with (folder / "legacy_rows.csv").open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=legacy_columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(legacy)
    write_csv(folder, "dose_mentions", " ".join(next(iter(doses.values())).keys()) if doses else
              "dose_id publication_id expression block_id start end arm_id arm_attribution origin " +
              " ".join(parse_dose("").keys()), (doses[key] for key in sorted(doses)))
    write_csv(folder, "legacy_dose_links", "dose_id legacy_id",
              (dict(dose_id=d, legacy_id=l) for d, l in sorted(dose_links)))
    write_csv(folder, "review_flags", "record_type record_id reason",
              (dict(record_type=t, record_id=i, reason=r) for t, i, r in sorted(issues)))
    write_csv(folder, "targeted_source_checks",
              "publication_id doi factor finding source_url locator observation reported_expression quantity_role exposure dose_ids",
              dose_cases)
    private = folder / "local_evidence"
    private.mkdir()
    write_csv(private, "evidence_links", "evidence_id candidate_id block_id start end source_locator evidence_scope excerpt factor_match direction_match",
              (evidence[key] for key in sorted(evidence)))
    used_blocks = ({r["block_id"] for r in evidence.values()} |
                   {r["block_id"] for r in doses.values()}) - {""}
    used_blocks.update(b["block_id"] for pub in {r["publication_id"] for r in candidates.values()}
                       for b in blocks.get(pub, []))
    selected_blocks = {b["block_id"]: b for group in blocks.values() for b in group
                       if b["block_id"] in used_blocks}
    write_csv(private, "text_blocks", "block_id publication_id pmid source_id block_type text_sha256 text",
              (selected_blocks[key] for key in sorted(selected_blocks)))
    for item in list(evidence.values()) + list(doses.values()):
        if item["block_id"]:
            block = selected_blocks[item["block_id"]]
            excerpt = item.get("excerpt", item.get("expression"))
            if block["text"][item["start"]:item["end"]] != excerpt:
                raise ValueError(f"Invalid evidence offsets: {item}")
            cid = item.get("candidate_id")
            pub = candidates[cid]["publication_id"] if cid else item["publication_id"]
            if block["publication_id"] != pub:
                raise ValueError("Evidence attached to the wrong publication")
    flags = defaultdict(list)
    for scope, identifier, reason in sorted(issues):
        if scope == "candidate":
            flags[identifier].append(reason)
    ordered = sorted(candidates.values(), key=lambda r: (
        not flags[r["candidate_id"]], r["particle_candidate"].casefold() in MISSING,
        -r["evidence_count"], r["candidate_id"]))
    queue = []
    for entry in ordered:
        cid = entry["candidate_id"]
        pub = pubs[entry["publication_id"]]
        queue.append(dict(candidate_id=cid, pmid=entry["pmid"], title=pub["title"], doi=pub["doi"],
                          factor=entry["factor_legacy_label"], direction=entry["direction_candidate"],
                          particle_hint=entry["particle_candidate"], status=entry["relation_status"],
                          flags="|".join(flags[cid]), evidence_count=entry["evidence_count"], url=pub["url"]))
    write_csv(folder, "review_queue", "candidate_id pmid title doi factor direction particle_hint status flags evidence_count url", queue)
    write_csv(folder, "screening_queue", "publication_id pmid title publication_types status url",
              (dict(publication_id=p["publication_id"], pmid=p["pmid"], title=p["title"],
                    publication_types=p.get("publication_types", ""), status=p["screening_status"],
                    url=p["url"]) for p in pubs.values()))
    reviewer_columns = ("candidate_id finding_key reviewer_id decision reason evidence_locator codebook_version "
                        "factor_role perturbation comparison outcome time_point effect_direction "
                        "experiment_key index_arm reference_arm particle_confirmed exposure_locator")
    write_csv(folder, "reviewer_form", reviewer_columns,
              (dict(candidate_id=row["candidate_id"], finding_key="1") for row in queue if row["status"] == "pending_review"))
    write_csv(folder, "screening_form", "publication_id stage reviewer_id decision reason evidence_locator codebook_version",
              (dict(publication_id=pub["publication_id"], stage="title_abstract")
               for pub in pubs.values() if pub["screening_status"] != "retracted"))
    eligible = sorted(key for key, row in candidates.items() if row["relation_status"] == "pending_review")
    sample = random.Random(args.seed).sample(eligible, min(400, len(eligible)))
    queue_by_id = {row["candidate_id"]: row for row in queue}
    write_csv(folder, "calibration_review_queue",
              "candidate_id pmid title doi factor direction particle_hint status flags evidence_count url",
              (queue_by_id[cid] for cid in sample))
    write_csv(folder, "candidate_calibration_sample", "candidate_id draw_order seed population_size inclusion_probability",
              (dict(candidate_id=c, draw_order=i, seed=args.seed, population_size=len(eligible),
                    inclusion_probability=len(sample) / len(eligible)) for i, c in enumerate(sample, 1)))
    stats = dict(
        stage="candidate_preparation", python=platform.python_version(), openpyxl=openpyxl_version, workbook_rows=len(legacy),
        workbook_rows_linked=sum(bool(row["resolved_pmid"]) for row in legacy),
        workbook_distinct_linked_pmids=len({r["resolved_pmid"] for r in legacy if r["resolved_pmid"]}),
        workbook_match_methods=dict(Counter(row["identity_method"] for row in legacy)),
        publications=len(pubs), historical_unique_pmids=len({r["publication_id"] for r in sources
                                                               if r["capture"] == "historical_nbib"}),
        captured_unique_pmids=len({r["publication_id"] for r in sources if r["capture"] != "historical_nbib"}),
        captures=sorted({r["capture"] for r in sources}),
        publications_scanned=len(scan_pubs), candidates=len(candidates),
        candidate_status_counts=dict(Counter(row["relation_status"] for row in candidates.values())),
        candidate_origin_counts=dict(Counter(origin for _, origin in candidate_sources)),
        historical_audit_distinct_candidates=len(set(audit_candidates)),
        legacy_candidate_links=len(crosswalk), evidence_links=len(evidence),
        evidence_links_with_source_offsets=sum(bool(x["block_id"]) for x in evidence.values()),
        normalized_dose_mentions=len(doses), dose_parse_status=dict(Counter(x["parse_status"] for x in doses.values())),
        dose_mentions_with_arm=0, verified_dose_exposure_contexts=sum(
            x["arm_attribution"] == "exposure_context_verified" for x in doses.values()), reviewed_source_checks=len(dose_cases), accepted_relations=0,
        flags=dict(Counter(reason for _, _, reason in issues)), seed=args.seed)
    (folder / "summary.json").write_text(json.dumps(stats, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    inventory = {str(file.relative_to(folder)): digest(file) for file in sorted(folder.rglob("*")) if file.is_file()}
    (folder / "checksums.json").write_text(json.dumps(inventory, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(stats, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workbook", required=True, type=Path)
    parser.add_argument("--general", nargs="+", required=True, type=Path)
    parser.add_argument("--proton", nargs="+", required=True, type=Path)
    parser.add_argument("--direction-audit", type=Path)
    parser.add_argument("--capture", action="append", default=[], type=Path)
    parser.add_argument("--scan-archive", action="store_true",
                        help="Apply historical matchers to archived abstracts as well as captures.")
    parser.add_argument("--seed", type=int, default=20261113)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.exists():
        parser.error("Output already exists. Use a new versioned directory.")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".radbionet-", dir=args.output.parent) as temp:
        folder = Path(temp) / "build"
        folder.mkdir()
        build(args, folder)
        folder.rename(args.output)


if __name__ == "__main__":
    main()
