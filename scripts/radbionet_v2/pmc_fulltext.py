"""Inventory PMC open-access XML for RadBioNET and download it on demand."""

import argparse
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
import csv
from datetime import datetime, timezone
import gzip
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import time
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, urlencode, urlparse
from urllib.request import Request, urlopen
import xml.etree.ElementTree as ET

from .pubmed import local_name

EUTILS = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/"
OAI = "https://pmc.ncbi.nlm.nih.gov/api/oai/v1/mh/"
BUCKET = "pmc-oa-opendata"
CLOUD = f"https://{BUCKET}.s3.amazonaws.com/"
INVENTORY = "inventory-reports/pmc-oa-opendata/metadata/"
OA_FILTER = "open_access[filter] NOT pmc embargo[filter]"
INVENTORY_FIELDS = ["Bucket", "Key", "LastModifiedDate", "ETag"]
METADATA_KEY = re.compile(r"metadata/(PMC[0-9]+)\.([1-9][0-9]*)\.json\Z")
SEARCH_BATCH = 2000
SUMMARY_BATCH = 400


def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def batches(values, size):
    for index in range(0, len(values), size):
        yield values[index:index + size]


def request(url, data=None):
    req = Request(url, data=data, headers={"User-Agent": "RadBioNET/2 PMC corpus"})
    for attempt in range(5):
        try:
            with urlopen(req, timeout=100) as response:
                return response.read()
        except HTTPError as exc:
            if exc.code not in {408, 429, 500, 502, 503, 504} or attempt == 4:
                raise
            retry_after = exc.headers.get("Retry-After", "")
            delay = min(60, int(retry_after)) if retry_after.isdigit() else 2 ** attempt
        except (OSError, URLError):
            if attempt == 4:
                raise
            delay = 2 ** attempt
        time.sleep(delay)


def write_atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix=f".{path.name}.", delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(data)
            stream.close()
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def write_json(path, data):
    write_atomic(path, (json.dumps(data, indent=2, ensure_ascii=False) + "\n").encode())


def write_csv(path, fields, rows):
    stream = io.StringIO()
    writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    write_atomic(path, stream.getvalue().encode())


def csv_rows(path):
    with path.open(newline="", encoding="utf-8-sig") as stream:
        yield from csv.DictReader(stream)


def cohorts(prepared):
    historical = {
        row["publication_id"].removeprefix("pmid:")
        for row in csv_rows(prepared / "publication_sources.csv")
        if row["capture"] == "historical_nbib"
    }
    legacy = {row["resolved_pmid"] for row in csv_rows(prepared / "legacy_rows.csv")
              if row["resolved_pmid"]}
    if not historical or not legacy or not legacy <= historical:
        raise ValueError("The historical corpus is empty or the legacy PMID set is incomplete")
    if not all(re.fullmatch(r"[1-9][0-9]*", pmid) for pmid in historical):
        raise ValueError("The historical corpus contains invalid PMIDs")
    return historical, legacy


class NCBI:
    def __init__(self):
        self.last = 0.0
        self.identity = {"tool": "radbionet"}
        for parameter, variable in [("email", "NCBI_EMAIL"), ("api_key", "NCBI_API_KEY")]:
            value = os.getenv(variable)
            if value:
                self.identity[parameter] = value
        self.interval = 0.12 if "api_key" in self.identity else 0.36

    def call(self, endpoint, **params):
        time.sleep(max(0.0, self.last + self.interval - time.monotonic()))
        try:
            return json.loads(request(EUTILS + endpoint + ".fcgi",
                                      urlencode({"db": "pmc", "retmode": "json",
                                                 **self.identity, **params}).encode()))
        finally:
            self.last = time.monotonic()


def find_oa(client, historical, cache):
    ids = sorted(historical, key=int)
    pmid_batches = {pmid: i // SEARCH_BATCH + 1 for i, pmid in enumerate(ids)}
    search_runs = []
    pmc_batches = {}
    for index, batch in enumerate(batches(ids, SEARCH_BATCH), 1):
        term = "(" + " OR ".join(f"{pmid}[pmid]" for pmid in batch) + ") AND " + OA_FILTER
        path = cache / f"esearch_{index:03d}.json"
        if path.is_file():
            run = json.loads(path.read_text())
            if run["term"] != term:
                raise ValueError(f"Search cache does not match the input PMIDs: {path}")
        else:
            result = client.call("esearch", term=term, retmax=len(batch))["esearchresult"]
            run = {"term": term, "retrieved_utc": utc_now(), "result": result}
        result = run["result"]
        returned = set(result["idlist"])
        if (result.get("errorlist") or int(result["count"]) != len(returned)
                or len(returned) != len(result["idlist"])):
            raise ValueError(f"PMC ESearch batch {index} was incomplete: {result.get('errorlist')}")
        translated_pmids = set(re.findall(r'"([0-9]+)"\[PMID\]', result["querytranslation"]))
        if translated_pmids != set(batch):
            raise ValueError(f"PMC ESearch changed the PMID scope of batch {index}")
        previous = returned.intersection(pmc_batches)
        if previous:
            raise ValueError(f"PMC IDs matched multiple disjoint PMID batches: {sorted(previous)[:5]}")
        if not path.is_file():
            write_json(path, run)
        pmc_batches.update((uid, index) for uid in returned)
        search_runs.append({"batch": index, "pmids": len(batch), "matched_pmcids": len(returned),
                            "retrieved_utc": run["retrieved_utc"]})
        print(f"PMC search batch {index}: {len(returned)} OA results", file=sys.stderr, flush=True)
    matches = {}
    for index, batch in enumerate(batches(sorted(pmc_batches, key=int), SUMMARY_BATCH), 1):
        path = cache / f"esummary_{index:03d}.json"
        if path.is_file():
            lookup = json.loads(path.read_text())
            if lookup["ids"] != batch:
                raise ValueError(f"PMC summary cache does not match the retrieved IDs: {path}")
        else:
            lookup = {"ids": batch, "result": client.call("esummary", id=",".join(batch))["result"]}
        result = lookup["result"]
        if set(result["uids"]) != set(batch):
            raise ValueError(f"PMC ESummary batch {index} did not return all requested identifiers")
        for uid in batch:
            pmcid = f"PMC{uid}"
            identifiers = {entry["idtype"]: entry["value"] for entry in result[uid]["articleids"]}
            pmid = str(identifiers.get("pmid", ""))
            if identifiers.get("pmcid") != pmcid or pmid not in historical:
                raise ValueError(f"PMC ESummary identity mismatch for {pmcid}: {identifiers}")
            if pmid_batches[pmid] != pmc_batches[uid]:
                raise ValueError(f"{pmcid} returned outside its PMID batch")
            matches[pmcid] = pmid
        if not path.is_file():
            # Keep only identity fields in the saved summaries.
            compact = {uid: {"articleids": result[uid]["articleids"]} for uid in batch}
            write_json(path, {"ids": batch, "result": {"uids": batch, **compact}})
        if index % 10 == 0:
            print(f"Verified PMC identifiers in {index} summary batches", file=sys.stderr, flush=True)
    return matches, search_runs


def get_inventory(inventory_date):
    if inventory_date is None:
        url = CLOUD + "?" + urlencode({"list-type": 2, "prefix": INVENTORY, "delimiter": "/"})
        root = ET.fromstring(request(url))
        dates = [
            node.text.removeprefix(INVENTORY).rstrip("/")
            for node in root.findall("./{*}CommonPrefixes/{*}Prefix")
            if node.text and re.fullmatch(re.escape(INVENTORY) + r"\d{4}-\d{2}-\d{2}T\d{2}-\d{2}Z/", node.text)
        ]
        if root.findtext("./{*}IsTruncated") != "false" or not dates:
            raise ValueError("Could not identify the latest PMC Cloud inventory snapshot")
        inventory_date = max(dates)
    url = CLOUD + INVENTORY + inventory_date + "/manifest.json"
    manifest = json.loads(request(url))
    if (manifest["sourceBucket"] != BUCKET or manifest["fileFormat"] != "CSV"
            or [x.strip() for x in manifest["fileSchema"].split(",")] != INVENTORY_FIELDS
            or not manifest["files"]):
        raise ValueError(f"Unexpected inventory layout at {url}")
    return url, manifest


def inventory_shard(shard, pmcids):
    key = shard["key"]
    if not key.startswith(INVENTORY + "data/"):
        raise ValueError(f"Unexpected PMC Cloud inventory shard: {key}")
    data = request(CLOUD + quote(key, safe="/"))
    if len(data) != shard["size"] or hashlib.md5(data).hexdigest() != shard["MD5checksum"]:
        raise ValueError(f"PMC Cloud inventory checksum mismatch: {key}")
    selected = defaultdict(list)
    with gzip.GzipFile(fileobj=io.BytesIO(data)) as zipped:
        with io.TextIOWrapper(zipped, encoding="utf-8", newline="") as stream:
            for bucket, item, modified, etag in csv.reader(stream):
                match = METADATA_KEY.fullmatch(item)
                if bucket == BUCKET and match and match[1] in pmcids:
                    selected[match[1]].append((int(match[2]), etag.strip('"'), modified))
    return selected


def inventory_versions(manifest, pmcids):
    selected = defaultdict(dict)
    with ThreadPoolExecutor(max_workers=4) as pool:
        for part in pool.map(lambda shard: inventory_shard(shard, pmcids), manifest["files"]):
            for pmcid, versions in part.items():
                for version, etag, date in versions:
                    if version in selected[pmcid] and selected[pmcid][version] != (etag, date):
                        raise ValueError(f"Conflicting inventory rows for {pmcid}.{version}")
                    selected[pmcid][version] = (etag, date)
    return selected


def oai_url(verb, pmcid, **kwargs):
    return OAI + "?" + urlencode(dict(verb=verb, identifier=f"oai:pubmedcentral.nih.gov:{pmcid[3:]}",
                                      **kwargs))


def oai_supports_fulltext(pmcid):
    response = ET.fromstring(request(oai_url("ListMetadataFormats", pmcid)))
    error = response.find("./{*}error")
    if error is not None and error.get("code") not in {"idDoesNotExist", "noMetadataFormats"}:
        raise ValueError(f"PMC OAI-PMH metadata error for {pmcid}: {error.text}")
    return any(node.text == "pmc" for node in response.findall("./{*}ListMetadataFormats/{*}metadataFormat/{*}metadataPrefix"))


def check(args):
    historical, legacy = cohorts(args.prepared)
    output = args.output
    if (output / "summary.json").exists():
        raise FileExistsError(f"A completed check already exists: {output}")
    matches, search_runs = find_oa(NCBI(), historical, output / "cache")
    inventory_url, manifest = get_inventory(args.inventory_date)
    print(f"Checking {len(matches)} PMC IDs against {inventory_url}", file=sys.stderr, flush=True)
    versions = inventory_versions(manifest, matches.keys())
    write_coverage(output, historical, legacy, matches, search_runs, inventory_url, manifest, versions)


def write_coverage(output, historical, legacy, matches, search_runs, inventory_url, manifest, versions):
    by_pmid = defaultdict(list)
    for pmcid, pmid in matches.items():
        by_pmid[pmid].append(pmcid)
    coverage = []
    plan = []
    for pmid in sorted(historical, key=int):
        links = sorted(by_pmid[pmid], key=lambda value: int(value[3:]))
        cloud = [pmcid for pmcid in links if versions.get(pmcid)]
        oai = []
        if not cloud:
            for pmcid in links:
                if oai_supports_fulltext(pmcid):
                    oai.append(pmcid)
                time.sleep(0.36)
        status = "no_pmc_oa_match"
        if cloud:
            status = "cloud_listed"
        elif oai:
            status = "oai_listed"
        elif links:
            status = "oa_index_only"
        base = dict(pmid=pmid, in_legacy_annotations=int(pmid in legacy))
        coverage.append(dict(**base, oa_pmcids="|".join(links), cloud_pmcids="|".join(cloud),
                             oai_pmcids="|".join(oai), status=status))
        for pmcid in cloud:
            for version, (etag, date) in sorted(versions[pmcid].items(), reverse=True):
                plan.append(dict(**base, pmcid=pmcid, version=version, distribution="cloud",
                                 metadata_etag=etag, metadata_modified_utc=date))
        for pmcid in oai:
            plan.append(dict(**base, pmcid=pmcid, distribution="oai"))
    summary = {
        "checked_utc": utc_now(), "pmc_filter": OA_FILTER,
        "inventory_manifest_url": inventory_url,
        "inventory_created_utc": datetime.fromtimestamp(
            int(manifest["creationTimestamp"]) / 1000, timezone.utc).isoformat(),
        "search_first_utc": search_runs[0]["retrieved_utc"],
        "search_last_utc": search_runs[-1]["retrieved_utc"],
    }
    for name, cohort in [("historical", historical), ("legacy_annotations", legacy)]:
        rows = [row for row in coverage if row["pmid"] in cohort]
        status = [row["status"] for row in rows]
        summary[name] = dict(pmids=len(rows), oa_pmc_matched=sum(bool(row["oa_pmcids"]) for row in rows),
                             cloud_listed=status.count("cloud_listed"), oai_listed=status.count("oai_listed"),
                             fulltext_listed=status.count("cloud_listed") + status.count("oai_listed"),
                             oa_index_only=status.count("oa_index_only"))
    write_csv(output / "coverage.csv", list(coverage[0]), coverage)
    write_csv(output / "download_plan.csv",
              ["pmid", "pmcid", "version", "in_legacy_annotations", "distribution",
               "metadata_etag", "metadata_modified_utc"],
              plan)
    write_json(output / "inventory_manifest.json", manifest)
    write_json(output / "search_runs.json", search_runs)
    write_json(output / "summary.json", summary)
    print(json.dumps(summary, indent=2))


def xml_location(value, article_version):
    source = urlparse(value)
    path = f"/{article_version}/{article_version}.xml"
    md5 = parse_qs(source.query).get("md5", [""])[0]
    if (source.scheme != "s3" or source.netloc != BUCKET or source.path != path
            or not re.fullmatch(r"[0-9a-fA-F]{32}", md5)):
        raise ValueError(f"Unexpected PMC XML location for {article_version}")
    return CLOUD + path.lstrip("/"), md5.lower()


def read_download_plan(path, cohort):
    published_pmids = {}
    planned = defaultdict(list)
    seen = set()
    for row in csv_rows(path):
        pmid, pmcid, version = row["pmid"], row["pmcid"], row["version"]
        distribution = row["distribution"]
        if (not re.fullmatch(r"[1-9][0-9]*", pmid)
                or not re.fullmatch(r"PMC[1-9][0-9]*", pmcid)
                or distribution not in {"cloud", "oai"}
                or distribution == "cloud" and not re.fullmatch(r"[1-9][0-9]*", version)
                or distribution == "oai" and version):
            raise ValueError(f"Invalid identifier in download plan: {row}")
        if published_pmids.setdefault(pmcid, pmid) != pmid or (pmcid, version) in seen:
            raise ValueError(f"Conflicting or duplicate PMC version: {pmcid}.{version}")
        seen.add((pmcid, version))
        if cohort == "historical" or row["in_legacy_annotations"] == "1":
            planned[pmid].append(row)
    return planned


def existing_article(pmid, allowed, output):
    sidecar = output / "records" / f"{pmid}.json"
    if sidecar.is_file():
        saved = json.loads(sidecar.read_text())
        version = saved["article_version"]
        if version in allowed:
            path = output / "xml" / f"{version}.xml"
            if path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == saved["xml_sha256"]:
                return dict(saved, status="existing")
    return None


def save_article(output, record, payload):
    version = record["article_version"]
    record["xml_sha256"] = hashlib.sha256(payload).hexdigest()
    record["downloaded_utc"] = utc_now()
    write_atomic(output / "xml" / f"{version}.xml", payload)
    write_json(output / "records" / f"{record['pmid']}.json", record)
    return dict(record, status="downloaded")


def fetch_article(pmid, versions, output):
    allowed = {f"{row['pmcid']}.{row['version']}" for row in versions}
    existing = existing_article(pmid, allowed, output)
    if existing is not None:
        return existing
    issues = []
    for row in sorted(versions, key=lambda r: (-int(r["version"]), int(r["pmcid"][3:]))):
        version = f"{row['pmcid']}.{row['version']}"
        metadata_url = CLOUD + f"metadata/{version}.json"
        try:
            raw = request(metadata_url)
            meta = json.loads(raw)
            if (meta["pmcid"] != row["pmcid"] or str(meta["pmid"]) != pmid
                    or str(meta["version"]) != row["version"]):
                raise ValueError("metadata identity differs from the download plan")
            if meta.get("is_pmc_openaccess") is not True or not meta.get("license_code"):
                raise ValueError("this version has no OA status or licence in the metadata")
            url, md5 = xml_location(meta.get("xml_url") or "", version)
            payload = request(url)
            if hashlib.md5(payload).hexdigest() != md5:
                raise ValueError("XML checksum differs from PMC metadata")
            article = ET.fromstring(payload)
            if local_name(article) != "article" or article.find("./{*}body") is None:
                raise ValueError("downloaded XML has no JATS article body")
        except (OSError, ValueError, KeyError, ET.ParseError) as error:
            issues.append(f"{version}: {error}")
            continue
        record = dict(
            pmid=pmid, pmcid=row["pmcid"], article_version=version, doi=meta.get("doi"),
            license_code=meta["license_code"], is_manuscript=meta.get("is_manuscript"),
            is_retracted=meta.get("is_retracted"), metadata_url=metadata_url, xml_url=url,
            xml_md5=md5, distribution="cloud",
            metadata_md5=hashlib.md5(raw).hexdigest(), inventory_etag=row["metadata_etag"],
        )
        write_json(output / "metadata" / f"{version}.json", meta)
        return save_article(output, record, payload)
    return {"pmid": pmid, "status": "failed", "errors": issues}


def fetch_oai(pmid, links, output):
    existing = existing_article(pmid, {f"{row['pmcid']}.oai" for row in links}, output)
    if existing is not None:
        return existing
    issues = []
    for row in links:
        pmcid = row["pmcid"]
        url = oai_url("GetRecord", pmcid, metadataPrefix="pmc")
        try:
            raw = request(url)
            response = ET.fromstring(raw)
            container = response.find("./{*}GetRecord/{*}record")
            if container is None:
                raise ValueError("response has no OAI-PMH record")
            article = container.find("./{*}metadata/{*}article")
            if article is None or article.find("./{*}body") is None:
                raise ValueError("response has no JATS article body")
            identifiers = {node.get("pub-id-type"): (node.text or "").strip()
                           for node in article.findall("./{*}front/{*}article-meta/{*}article-id")}
            if identifiers.get("pmid") and identifiers["pmid"] != pmid:
                raise ValueError("article PMID differs from the download plan")
            if (identifiers.get("pmcid") or identifiers.get("pmc") or pmcid).removeprefix("PMC") != pmcid[3:]:
                raise ValueError("article PMCID differs from the download plan")
            licenses = article.findall("./{*}front/{*}article-meta/{*}permissions/{*}license")
            record = dict(
                pmid=pmid, pmcid=pmcid, article_version=f"{pmcid}.oai", doi=identifiers.get("doi"),
                distribution="oai", xml_url=url, oai_datestamp=container.findtext("./{*}header/{*}datestamp"),
                oai_response_sha256=hashlib.sha256(raw).hexdigest(),
                licenses=[ET.tostring(node, encoding="unicode") for node in licenses],
            )
            payload = ET.tostring(article, encoding="utf-8", xml_declaration=True)
        except (OSError, ValueError, ET.ParseError) as error:
            issues.append(f"{pmcid}: {error}")
            continue
        finally:
            time.sleep(0.36)
        return save_article(output, record, payload)
    return {"pmid": pmid, "status": "failed", "errors": issues}


def download(args):
    planned = read_download_plan(args.plan, args.cohort)
    selected = sorted(planned, key=int)
    if args.limit is not None:
        selected = selected[:args.limit]
    if not selected:
        raise ValueError("The selected cohort has no planned downloads")
    cloud = [pmid for pmid in selected if planned[pmid][0]["distribution"] == "cloud"]
    oai = [pmid for pmid in selected if planned[pmid][0]["distribution"] == "oai"]
    with ThreadPoolExecutor(max_workers=4) as pool:
        results = []
        for index, row in enumerate(pool.map(lambda pmid: fetch_article(pmid, planned[pmid], args.output),
                                            cloud), 1):
            results.append(row)
            if index % 100 == 0:
                print(f"Processed {index}/{len(selected)} PMIDs", file=sys.stderr, flush=True)
    results.extend(fetch_oai(pmid, planned[pmid], args.output) for pmid in oai)
    summary = {"cohort": args.cohort, "selected": len(selected)}
    for status in ("downloaded", "existing", "failed"):
        summary[status] = sum(row["status"] == status for row in results)
    write_json(args.output / "last_download.json", {"summary": summary, "records": results})
    print(json.dumps(summary, indent=2))
    if summary["failed"]:
        raise SystemExit(1)


def positive_integer(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("expected a positive integer")
    return number


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    inventory = sub.add_parser("check", help="find OA articles using search and inventory metadata")
    inventory.add_argument("--prepared", required=True, type=Path)
    inventory.add_argument("--output", required=True, type=Path)
    inventory.add_argument("--inventory-date", help="a PMC inventory snapshot, such as 2026-11-15T01-00Z")
    inventory.set_defaults(run=check)
    retrieve = sub.add_parser("download", help="download JATS XML from a completed PMC plan")
    retrieve.add_argument("--plan", required=True, type=Path)
    retrieve.add_argument("--output", required=True, type=Path)
    retrieve.add_argument("--cohort", choices=("legacy", "historical"), default="legacy")
    retrieve.add_argument("--limit", type=positive_integer, help="use the first N PMIDs for a pilot")
    retrieve.set_defaults(run=download)
    args = parser.parse_args()
    args.run(args)


if __name__ == "__main__":
    main()
