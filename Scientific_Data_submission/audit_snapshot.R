#!/usr/bin/env Rscript

# From the RadBioNET repository root:
# Rscript --vanilla Scientific_Data_submission/audit_snapshot.R
# Append the upstream project directory to audit the archived inputs as well.

suppressPackageStartupMessages({
  library(readxl)
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 1L) stop("Provide at most one upstream project directory.")
root <- normalizePath(".", mustWork = TRUE)
data_dir <- file.path(root, "dados")
workbook <- "factor_v4_proton_therapy.xlsx"
cache <- "factor_v4_proton_therapy.rds"
x <- as.data.frame(read_excel(file.path(data_dir, workbook)))
rds <- readRDS(file.path(data_dir, cache))

blank <- function(value) is.na(value) | trimws(as.character(value)) == ""
split_labels <- function(value) strsplit(value, ";\\s*")
doi <- trimws(x$DOI)
title <- trimws(x$Title)
pmid <- trimws(as.character(x$PMID))
doc_key <- ifelse(!blank(doi), paste0("DOI:", doi),
  ifelse(!blank(pmid), paste0("PMID:", pmid),
    ifelse(!blank(title), paste0("TITLE:", title), paste0("ROW:", seq_len(nrow(x))))))
group_columns <- c("Title", "Factor", "Radiation particle category")
release_key <- data.frame(document = doc_key, factor = x$Factor,
  particle_category = x[["Radiation particle category"]])
toxicity <- unlist(split_labels(x[["Toxicity endpoint"]][!blank(x[["Toxicity endpoint"]])]))

cat("Primary table\n")
print(c(rows = nrow(x), fields = ncol(x), factors = uniqueN(x$Factor),
  titles = uniqueN(title), document_keys = uniqueN(doc_key),
  doi_values = uniqueN(doi[!blank(doi)]), duplicate_rows = sum(duplicated(x)),
  repeated_release_keys = sum(duplicated(release_key)),
  repeated_title_factor_category = sum(duplicated(x[group_columns])),
  direction_count_disagreements = sum(lengths(split_labels(x$Direction)) != x[["Direction labels (n)"]]),
  artifact_label_rows = sum(grepl("Likely artifact", x[["Particle-specific verdict"]], fixed = TRUE)),
  toxicity_labels = length(toxicity), distinct_toxicity_labels = uniqueN(toxicity)))
cat("Spreadsheet and RDS value equality:", identical(x, rds), "\n")
print(table(x[["Quality flag"]], useNA = "ifany"))
print(table(x[["Radiation particle category"]], useNA = "ifany"))
cat("Blank or missing values by field\n")
print(vapply(x, function(column) sum(blank(column)), integer(1)))
cat("Explicit unresolved labels\n")
print(vapply(x, function(column) sum(column %in% c("(Unknown)", "(none)", "Unspecified")), integer(1)))

dose <- fread(file.path(data_dir, "equipment_dose", "dose_distribution.csv"))
triples <- fread(file.path(data_dir, "knowledge_graph", "triples.csv"))
entities <- fread(file.path(data_dir, "knowledge_graph", "entities.csv"))
cat("\nDose token types\n")
print(table(dose[["Dose kind"]], useNA = "ifany"))
cat("Nonfinite single-dose values:", sum(!is.finite(dose[["Single dose (Gy)"]])), "\n")
print(dose[DOI == "10.1007/s00066-025-02411-1"])
cat("Primary rows with fractionation-like text:",
  sum(grepl("fraction|[0-9]\\s*[x×]\\s*[0-9]|Gy\\s*/", x[["Radiation dose"]],
    perl = TRUE, ignore.case = TRUE)), "\n")
source_script <- file.path(root, "scripts", "rebuild_data_from_xlsx.R")
expressions <- as.list(parse(source_script, encoding = "UTF-8"))
is_dose_parser <- function(expression) {
  is.call(expression) && identical(expression[[1L]], as.name("<-")) &&
    identical(expression[[2L]], as.name("parse_dose_tokens"))
}
parser <- new.env()
eval(Filter(is_dose_parser, expressions)[[1L]], envir = parser)
probe_doses <- c("50-60 Gy", "60 Gy / 30", "2 Gy x 5", "250 cGy", "3x8 Gy",
  "60 Gy in 30 fractions", "5 fractions of 2 Gy", "2 Gy/fraction", "60 Gy(RBE)")
parser_examples <- rbindlist(lapply(probe_doses, function(token) {
  result <- parser$parse_dose_tokens(token)
  result[, input := token]
  result
}))
cat("Dose parser probes\n")
print(parser_examples)
cat("\nGraph:", nrow(triples), "triples and", nrow(entities), "typed entities\n")
print(triples[, .N, by = predicate])
cat("Community counts\n")
print(table(fread(file.path(data_dir, "network", "nodes.csv"))$community))

if (length(args) == 1L) {
  upstream <- normalizePath(args[1], mustWork = TRUE)
  general <- file.path(upstream, "除了质子以外的")
  proton <- file.path(upstream, "质子单独放在这里")
  normalize_title <- function(value) {
    sub("[.]+$", "", trimws(gsub("[[:space:]]+", " ", tolower(value))))
  }
  read_nbib <- function(path) {
    lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
    record_starts <- grep("^PMID-\\s*[0-9]+", lines, perl = TRUE)
    pmids <- sub("^PMID-\\s*", "", lines[record_starts], perl = TRUE)
    doi_pattern <- "^(AID|LID) -\\s*(10\\..+?)\\s+\\[doi\\]$"
    doi_lines <- grep(doi_pattern, lines, perl = TRUE)
    doi_links <- data.table(
      id = tolower(trimws(sub(doi_pattern, "\\2", lines[doi_lines], perl = TRUE))),
      pmid = pmids[findInterval(doi_lines, record_starts)])
    title_starts <- grep("^TI  - ", lines)
    boundaries <- c(which(!startsWith(lines, "      ")), length(lines) + 1L)
    title_ends <- boundaries[findInterval(title_starts, boundaries) + 1L] - 1L
    titles <- vapply(seq_along(title_starts), function(i) {
      text <- paste(lines[title_starts[i]:title_ends[i]], collapse = " ")
      normalize_title(sub("^TI  - ", "", text))
    }, character(1))
    title_links <- data.table(id = titles, pmid = pmids[findInterval(title_starts, record_starts)])
    list(pmids = pmids, doi = doi_links, title = title_links)
  }
  general_exports <- lapply(list.files(file.path(general, "pubmed_nbib"),
    "\\.nbib$", full.names = TRUE), read_nbib)
  proton_exports <- lapply(list.files(proton, "\\.nbib$", full.names = TRUE), read_nbib)
  general_exports_pmids <- lapply(general_exports, `[[`, "pmids")
  proton_exports_pmids <- lapply(proton_exports, `[[`, "pmids")
  general_ids <- unique(unlist(general_exports_pmids))
  proton_ids <- unique(unlist(proton_exports_pmids))
  cat("\nArchived PubMed inputs\n")
  print(list(general_file_counts = lengths(general_exports_pmids),
    proton_file_counts = lengths(proton_exports_pmids), general_unique = length(general_ids),
    proton_unique = length(proton_ids), overlap = length(intersect(general_ids, proton_ids)),
    union = length(union(general_ids, proton_ids))))
  exports <- c(general_exports, proton_exports)
  doi_links <- rbindlist(lapply(exports, `[[`, "doi"))
  title_links <- rbindlist(lapply(exports, `[[`, "title"))
  matches <- function(keys, lookup) {
    result <- merge(data.table(id = unique(keys)), lookup, by = "id", all.x = TRUE)
    result[, uniqueN(pmid, na.rm = TRUE), by = id][, table(V1)]
  }
  cat("Number of archive PMID matches per distinct nonblank release DOI\n")
  print(matches(tolower(doi[!blank(doi)]), doi_links))
  cat("Number of archive PMID matches per distinct DOI-missing release title\n")
  print(matches(normalize_title(title[blank(doi)]), title_links))

  master <- file.path(general, "proton_therapy_FACTOR_REFINED_MASTER_v2.xlsx")
  papers <- read_excel(master, sheet = "3_Paper_level_MASTER_v2", .name_repair = "minimal")
  relations <- read_excel(master, sheet = "2_Factor_level_MASTER_v2")
  legacy_audit <- read_excel(master, sheet = "4_Pair_audit_v2")
  strong <- legacy_audit[["Same-sentence support"]]
  total <- legacy_audit[["Total papers"]]
  verdict <- fcase(strong == 0, "Likely artifact", strong / total >= 0.5, "Likely real",
    strong >= 2, "Partially supported", default = "Weak")
  match_groups <- merge(unique(x[group_columns]), unique(relations[group_columns]),
    by = group_columns)
  cat("Historical workbook\n")
  print(c(paper_rows = nrow(papers), distinct_titles = uniqueN(papers$Title),
    current_titles_found = sum(unique(x$Title) %in% papers$Title),
    historical_factor_rows = nrow(relations), current_groups_found = nrow(match_groups),
    audited_verdicts = length(verdict), matching_verdicts = sum(verdict == legacy_audit$Verdict)))
  print(table(papers[["Source batch"]]))
}

cat("\nDownstream rebuild in a temporary directory using LC_ALL=C\n")
sandbox <- tempfile("radbionet-rebuild-")
dir.create(file.path(sandbox, "dados"), recursive = TRUE)
tryCatch({
  stopifnot(file.copy(file.path(data_dir, workbook), file.path(sandbox, "dados", workbook)))
  script <- file.path(sandbox, "rebuild_data_from_xlsx.R")
  stopifnot(file.copy(source_script, script))
  previous_dir <- setwd(sandbox)
  tryCatch({
    status <- system2(file.path(R.home("bin"), "Rscript"),
      c("--vanilla", shQuote(script)), env = "LC_ALL=C")
    if (status != 0L) stop("Downstream rebuild failed.")
  }, finally = setwd(previous_dir))
  rebuilt_dir <- file.path(sandbox, "dados")
  stopifnot(identical(rds, readRDS(file.path(rebuilt_dir, cache))))
  products <- list.files(rebuilt_dir, "\\.(csv|json)$", recursive = TRUE)
  same <- unname(tools::md5sum(file.path(data_dir, products))) ==
    unname(tools::md5sum(file.path(rebuilt_dir, products)))
  print(data.frame(product = products, byte_match = same))
  if (!all(same)) stop("At least one rebuilt derivative differs.")
}, finally = unlink(sandbox, recursive = TRUE))
