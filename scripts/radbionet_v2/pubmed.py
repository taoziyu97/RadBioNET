"""Capture a versioned PubMed query and its XML results."""
import argparse
import csv
from datetime import date, datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import xml.etree.ElementTree as ET


def local_name(element):
    return element.tag.rsplit("}", 1)[-1]


def parse_articles(path):
    for _, article in ET.iterparse(path, events=("end",)):
        if local_name(article) not in {"PubmedArticle", "PubmedBookArticle"}:
            continue
        citation = article.find("MedlineCitation")
        if citation is None:
            citation = article.find("BookDocument")
        if citation is None:
            raise ValueError(f"Missing citation in {path}")
        pmid = citation.findtext("PMID", "")
        fields = {"PMID": [pmid]}
        paths = {
            "TI": ".//ArticleTitle", "AB": ".//Abstract/AbstractText",
            "JT": ".//Journal/Title", "DP": ".//JournalIssue/PubDate",
            "PT": ".//PublicationType", "LA": ".//Language",
            "AID": "./PubmedData/ArticleIdList/ArticleId",
            "RIN": "./MedlineCitation/CommentsCorrectionsList/CommentsCorrections",
        }
        for key, xpath in paths.items():
            values = []
            nodes = article.findall(xpath)
            if key == "AID":
                # ReferenceList also has ArticleId nodes. Only read identifiers of this citation.
                nodes += article.findall("./PubmedBookData/ArticleIdList/ArticleId")
                nodes += citation.findall("./Article/ELocationID")
            for node in nodes:
                value = (" ".join(node.itertext()) if key == "DP" else "".join(node.itertext())).strip()
                if key == "AB" and node.get("Label"):
                    value = f"{node.get('Label')}: {value}"
                if key == "AID":
                    if (node.get("IdType") or node.get("EIdType")) != "doi":
                        continue
                    value += " [doi]"
                if key == "RIN":
                    value = f"{node.get('RefType', '')}:{node.findtext('PMID', '')}"
                if value:
                    values.append(value)
            fields[key] = values
        yield fields
        article.clear()


def queries(path):
    raw = path.read_text()
    parts = re.split(r"^(GENERAL STREAM|FOCUSED PROTON STREAM|RETRIEVAL CONTROL)\s*$",
                     raw, flags=re.M)
    sections = dict(zip(parts[1::2], parts[2::2]))
    result = {}
    for label, key in [("GENERAL STREAM", "general"), ("FOCUSED PROTON STREAM", "proton")]:
        base, removed = re.subn(
            r'AND\s*\("2000/01/01"\[Date - Publication\]\s*:\s*"END_DATE"\[Date - Publication\]\)\s*$',
            "", sections[label].strip())
        if removed != 1:
            raise ValueError(f"{label}: missing expected date clause")
        result[key] = " ".join(base.split())
    return result


def run(args):
    if args.start > args.end:
        raise ValueError("Start must be on or before end")
    expressions = queries(args.query_file)
    key = os.getenv("NCBI_API_KEY")
    email = os.getenv("NCBI_EMAIL")
    last = 0.0

    def call(endpoint, **params):
        nonlocal last
        params.update(db="pubmed", tool="radbionet")
        if key:
            params["api_key"] = key
        if email:
            params["email"] = email
        req = Request(f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/{endpoint}.fcgi",
                      data=urlencode(params).encode(), headers={"User-Agent": "RadBioNET/2"})
        for attempt in range(5):
            time.sleep(max(0, last + (0.12 if key else 0.36) - time.monotonic()))
            try:
                with urlopen(req, timeout=45) as response:
                    return response.read()
            except (HTTPError, URLError, TimeoutError) as exc:
                if attempt == 4 or isinstance(exc, HTTPError) and exc.code not in {429, 500, 502, 503, 504}:
                    raise RuntimeError(f"PubMed {endpoint} failed: {exc}") from None
                time.sleep(min(15, 2 ** attempt))
            finally:
                last = time.monotonic()

    args.output.mkdir(parents=True, exist_ok=False)
    started = datetime.now(timezone.utc).isoformat()
    runs, memberships = [], set()

    def search(stream, start, end):
        query = f'({expressions[stream]}) AND ("{start:%Y/%m/%d}"[dp] : "{end:%Y/%m/%d}"[dp])'
        raw = call("esearch", term=query, retmode="json", retmax=9999)
        name = f"{stream}_{start}_{end}.json"
        (args.output / name).write_bytes(raw)
        result = json.loads(raw)["esearchresult"]
        count = int(result["count"])
        ids = result["idlist"]
        warnings = result.get("warninglist", {})
        errors = result.get("errorlist", {})
        runs.append(dict(stream=stream, start=str(start), end=str(end), query=query, count=count,
                         returned=len(ids), translation=result["querytranslation"], raw=name,
                         warnings=warnings, errors=errors, terminal=count < 10000))
        if errors:
            raise ValueError(f"PubMed returned query errors for {stream}: {errors}")
        if count >= 10000:
            if start == end:
                raise ValueError("One day exceeds the ESearch limit. Capture this interval with NCBI EDirect.")
            middle = start + (end - start) // 2
            search(stream, start, middle)
            search(stream, middle + timedelta(days=1), end)
        else:
            if len(set(ids)) != count:
                raise ValueError(f"Incomplete identifier retrieval: {name}")
            memberships.update((stream, pmid) for pmid in ids)

    for stream in expressions:
        search(stream, args.start, args.end)
    pmids = sorted({pmid for _, pmid in memberships}, key=int)
    with (args.output / "memberships.csv").open("w", newline="") as fh:
        writer = csv.writer(fh, lineterminator="\n")
        writer.writerow(["stream", "pmid"])
        writer.writerows(sorted(memberships))
    for offset in range(0, len(pmids), 200):
        batch = pmids[offset:offset + 200]
        output = args.output / f"efetch_{offset // 200 + 1:04}.xml"
        output.write_bytes(call("efetch", id=",".join(batch), retmode="xml"))
        observed = [record["PMID"][0] for record in parse_articles(output)]
        if sorted(observed, key=int) != batch:
            raise ValueError(f"EFetch identifier mismatch: {output}")
    manifest = dict(mode=args.mode, query_sha256=hashlib.sha256(args.query_file.read_bytes()).hexdigest(),
                    started_utc=started, completed_utc=datetime.now(timezone.utc).isoformat(),
                    distinct_pmids=len(pmids), runs=runs,
                    files={p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                           for p in sorted(args.output.iterdir())})
    (args.output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"{len(pmids)} distinct PMIDs fetched ({args.mode}).")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query-file", required=True, type=Path)
    parser.add_argument("--start", required=True, type=date.fromisoformat)
    parser.add_argument("--end", required=True, type=date.fromisoformat)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--mode", choices=("pilot", "production"), default="pilot")
    run(parser.parse_args())


if __name__ == "__main__":
    main()
