#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readxl)
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(jsonlite)
})

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
xlsx_path <- file.path(root, "dados", "factor_v4_proton_therapy.xlsx")
rds_path <- file.path(root, "dados", "factor_v4_proton_therapy.rds")

if (!file.exists(xlsx_path)) stop("Missing input file: ", xlsx_path)

dir.create(file.path(root, "dados", "trends"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "dados", "equipment_dose"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "dados", "network"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "dados", "knowledge_graph"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(root, "dados", "external_links"), recursive = TRUE, showWarnings = FALSE)

split_multi <- function(x) {
  x <- as.character(x)
  x <- x[!is.na(x) & trimws(x) != ""]
  if (length(x) == 0) return(character(0))
  out <- unlist(strsplit(x, ";\\s*", perl = TRUE), use.names = FALSE)
  trimws(out[out != ""])
}

clean_unknown <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x) | x == "" | x %in% c("(none)", "Unknown", "(Unknown)")] <- "Unspecified"
  x
}

as_doc_id <- function(df) {
  doi <- trimws(as.character(df$DOI))
  pmid <- trimws(as.character(df$PMID))
  title <- trimws(as.character(df$Title))
  id <- ifelse(!is.na(doi) & doi != "", paste0("DOI:", doi),
    ifelse(!is.na(pmid) & pmid != "", paste0("PMID:", pmid), paste0("TITLE:", title)))
  id[is.na(id) | id == "TITLE:"] <- paste0("ROW:", seq_len(nrow(df))[is.na(id) | id == "TITLE:"])
  id
}

parse_gene_symbol <- function(factor_name) {
  x <- as.character(factor_name)
  x <- gsub("\\s*\\(.*?\\)", "", x)
  x <- gsub("[[:space:]]+", "", x)
  if (grepl("/", x, fixed = TRUE)) {
    parts <- unlist(strsplit(x, "/", fixed = TRUE), use.names = FALSE)
    cand <- parts[nchar(parts) >= 2][1]
  } else {
    cand <- x
  }
  cand <- gsub("[^A-Za-z0-9-]", "", cand)
  if (is.na(cand) || cand == "" || grepl("^[0-9]+$", cand)) return("")
  toupper(cand)
}

classify_model <- function(species, evidence) {
  s <- tolower(paste(species, evidence, sep = " ; "))
  if (grepl("patient|clinical|human \\(patient\\)", s, perl = TRUE)) return("Patient/clinical")
  if (grepl("mouse|mice|rat|animal|xenograft|murine", s, perl = TRUE)) return("Mouse/Animal")
  if (grepl("cell", s, perl = TRUE)) return("Cell line")
  "Unspecified"
}

parse_dose_tokens <- function(txt) {
  txt <- trimws(as.character(txt))
  if (is.na(txt) || txt == "") return(NULL)

  chunks <- unlist(strsplit(txt, ";\\s*", perl = TRUE), use.names = FALSE)
  chunks <- chunks[trimws(chunks) != ""]
  if (length(chunks) == 0) return(NULL)

  parse_one <- function(z) {
    z0 <- tolower(trimws(z))
    unit <- ifelse(grepl("cgy", z0), "cgy", "gy")
    mult <- ifelse(unit == "cgy", 0.01, 1)

    # Pattern: a-b Gy
    m_range <- regexec("([0-9]+\\.?[0-9]*)\\s*[-~to]+\\s*([0-9]+\\.?[0-9]*)", z0, perl = TRUE)
    r <- regmatches(z0, m_range)[[1]]
    if (length(r) == 3) {
      a <- as.numeric(r[2]) * mult
      b <- as.numeric(r[3]) * mult
      return(list(single = mean(c(a, b), na.rm = TRUE), total = NA_real_, fractions = NA_real_, kind = "range"))
    }

    # Pattern: total / fractions
    m_frac <- regexec("([0-9]+\\.?[0-9]*)\\s*gy\\s*/\\s*([0-9]+)", z0, perl = TRUE)
    f <- regmatches(z0, m_frac)[[1]]
    if (length(f) == 3) {
      total <- as.numeric(f[2])
      nfx <- as.numeric(f[3])
      return(list(single = total / nfx, total = total, fractions = nfx, kind = "fractionated"))
    }

    # Pattern: a Gy x n
    m_x <- regexec("([0-9]+\\.?[0-9]*)\\s*gy\\s*x\\s*([0-9]+)", z0, perl = TRUE)
    xx <- regmatches(z0, m_x)[[1]]
    if (length(xx) == 3) {
      single <- as.numeric(xx[2])
      nfx <- as.numeric(xx[3])
      return(list(single = single, total = single * nfx, fractions = nfx, kind = "fractionated"))
    }

    nums <- regmatches(z0, gregexpr("[0-9]+\\.?[0-9]*", z0, perl = TRUE))[[1]]
    nums <- as.numeric(nums)
    nums <- nums[is.finite(nums)]
    if (length(nums) == 0) return(NULL)
    v <- nums[1] * mult
    list(single = v, total = v, fractions = 1, kind = "single")
  }

  parsed <- lapply(chunks, parse_one)
  parsed <- parsed[!vapply(parsed, is.null, logical(1))]
  if (length(parsed) == 0) return(NULL)

  rbindlist(lapply(parsed, function(p) {
    data.table(
      single_dose_gy = p$single,
      total_dose_gy = p$total,
      fractions = p$fractions,
      dose_kind = p$kind
    )
  }), fill = TRUE)
}

cat("Reading master xlsx...\n")
df <- as.data.table(read_excel(xlsx_path))

# Keep app behavior deterministic for filters
for (col in c("Cancer type", "Evidence type", "Particle type")) {
  if (col %in% names(df)) {
    x <- as.character(df[[col]])
    x[is.na(x) | trimws(x) == ""] <- "(Unknown)"
    df[[col]] <- x
  }
}

saveRDS(as.data.frame(df), rds_path)
cat("Saved RDS:", rds_path, "\n")

df$doc_id <- as_doc_id(df)
df$year_num <- suppressWarnings(as.integer(df[["Publication year"]]))
df$strong_flag <- grepl("strong", tolower(as.character(df[["Quality flag"]])), fixed = TRUE)
df$row_id <- seq_len(nrow(df))

# -----------------------------
# Trends pack
# -----------------------------
timeline <- df[!is.na(year_num), .(
  papers = .N,
  strong_papers = sum(strong_flag, na.rm = TRUE)
), by = .(Factor, Year = year_num)][order(Factor, Year)]

overall <- df[!is.na(year_num), .(total_papers = .N), by = .(Year = year_num)][order(Year)]

factor_year <- timeline[, .(Factor, Year, papers)]

era_count <- function(y, a, b) sum(y >= a & y <= b, na.rm = TRUE)

trend_list <- lapply(split(factor_year, factor_year$Factor), function(d) {
  years <- d$Year
  papers <- d$papers
  total <- sum(papers, na.rm = TRUE)

  f_rows <- df[Factor == d$Factor[1]]
  total_strong <- sum(f_rows$strong_flag, na.rm = TRUE)

  e2000 <- sum(papers[years >= 2000 & years <= 2009], na.rm = TRUE)
  e2010 <- sum(papers[years >= 2010 & years <= 2014], na.rm = TRUE)
  e2015 <- sum(papers[years >= 2015 & years <= 2019], na.rm = TRUE)
  e2020 <- sum(papers[years >= 2020 & years <= 2022], na.rm = TRUE)
  e2023 <- sum(papers[years >= 2023 & years <= 2026], na.rm = TRUE)

  recent5 <- sum(papers[years >= 2021 & years <= 2026], na.rm = TRUE)
  past5 <- sum(papers[years >= 2015 & years <= 2020], na.rm = TRUE)
  ratio <- ifelse(past5 == 0, ifelse(recent5 > 0, recent5 + 1, 0), recent5 / past5)

  dfit <- d[d$Year >= 2010 & d$Year <= 2026, ]
  if (nrow(dfit) >= 3) {
    fit <- lm(papers ~ Year, data = dfit)
    slope <- unname(coef(fit)[2])
    pval <- summary(fit)$coefficients[2, 4]
    r2 <- summary(fit)$r.squared
  } else {
    slope <- 0
    pval <- 1
    r2 <- 0
  }

  tag <- "stable"
  if (slope >= 0.8 && pval < 0.05 && ratio >= 3) tag <- "rising fast"
  else if (slope >= 0.3 && pval < 0.1) tag <- "rising"
  else if (slope <= -0.3 && pval < 0.1) tag <- "declining"

  peak_idx <- which.max(papers)
  data.table(
    Factor = d$Factor[1],
    Total_papers = total,
    Total_strong = total_strong,
    Era_2000_09 = e2000,
    Era_2010_14 = e2010,
    Era_2015_19 = e2015,
    Era_2020_22 = e2020,
    Era_2023_26 = e2023,
    Recent_5yr_2021_26 = recent5,
    Past_5yr_2015_20 = past5,
    Recent_vs_past_ratio = round(ratio, 2),
    Trend_slope_2010_26 = round(slope, 3),
    Trend_p_value = round(pval, 4),
    Trend_r2 = round(r2, 4),
    Trend_tag = tag,
    Peak_year = d$Year[peak_idx],
    Peak_year_count = papers[peak_idx]
  )
})

factor_trends <- rbindlist(trend_list, fill = TRUE)[order(-Total_papers, Factor)]

era_distribution <- melt(
  factor_trends[, .(Factor, Era_2000_09, Era_2010_14, Era_2015_19, Era_2020_22, Era_2023_26)],
  id.vars = "Factor",
  variable.name = "Era",
  value.name = "papers"
)

hot_factors <- factor_trends[Trend_tag == "rising fast"][order(-Recent_vs_past_ratio, -Recent_5yr_2021_26)]
top_growth <- factor_trends[, .(
  Factor,
  Past_5yr_2015_20,
  Recent_5yr_2021_26,
  Absolute_growth = Recent_5yr_2021_26 - Past_5yr_2015_20,
  Recent_vs_past_ratio
)][order(-Absolute_growth, -Recent_vs_past_ratio)][1:min(20, .N)]

fwrite(timeline, file.path(root, "dados", "trends", "timeline_per_factor.csv"))
fwrite(factor_trends, file.path(root, "dados", "trends", "factor_trends.csv"))
fwrite(hot_factors, file.path(root, "dados", "trends", "hot_factors.csv"))
fwrite(top_growth, file.path(root, "dados", "trends", "top_growth_factors.csv"))
fwrite(era_distribution, file.path(root, "dados", "trends", "era_distribution.csv"))
fwrite(overall, file.path(root, "dados", "trends", "overall_papers_per_year.csv"))

# -----------------------------
# Equipment / dose pack
# -----------------------------

modality_long <- df[, .(Modality = split_multi(`Radiation modality`)), by = row_id]
modality_long <- modality_long[trimws(Modality) != "" & !is.na(Modality)]
modality_counts <- modality_long[, .(Papers = uniqueN(row_id)), by = Modality][order(-Papers, Modality)]

device_long <- df[, .(Device = split_multi(`Radiation platform/device`)), by = row_id]
device_long <- device_long[trimws(Device) != "" & !is.na(Device)]
device_counts <- device_long[, .(Papers = uniqueN(row_id)), by = Device][order(-Papers, Device)]
setnames(device_counts, "Device", "Device/platform")

part_mod <- merge(
  df[, .(row_id, part = clean_unknown(`Particle type`))],
  modality_long,
  by = "row_id",
  all = FALSE
)
if (nrow(part_mod) == 0) {
  particle_modality_crosstab <- data.table(`_part` = character(0))
} else {
  particle_modality_crosstab <- dcast(part_mod, part ~ Modality, fun.aggregate = length, value.var = "Modality")
  setnames(particle_modality_crosstab, "part", "_part")
}

# Dose distribution
dose_rows <- lapply(seq_len(nrow(df)), function(i) {
  parsed <- parse_dose_tokens(df$`Radiation dose`[i])
  if (is.null(parsed) || nrow(parsed) == 0) return(NULL)
  parsed[, `:=`(
    Model = classify_model(df$`Species/Source`[i], df$`Evidence type`[i]),
    `Particle category` = trimws(as.character(df$`Radiation particle category`[i])),
    `Cancer type` = trimws(as.character(df$`Cancer type`[i])),
    DOI = trimws(as.character(df$DOI[i])),
    Year = suppressWarnings(as.integer(df$`Publication year`[i])),
    Factor = trimws(as.character(df$Factor[i])),
    `Particle` = clean_unknown(df$`Particle type`[i])
  )]
  parsed
})
dose_dist <- rbindlist(dose_rows, fill = TRUE)

if (nrow(dose_dist) == 0) {
  dose_dist <- data.table(
    single_dose_gy = numeric(0), total_dose_gy = numeric(0), fractions = numeric(0),
    dose_kind = character(0), Model = character(0), `Particle category` = character(0),
    `Cancer type` = character(0), DOI = character(0), Year = integer(0),
    Factor = character(0), Particle = character(0)
  )
}

dose_by_model <- dose_dist[, .(
  `N papers (with parsable dose)` = .N,
  `Median single dose (Gy)` = median(single_dose_gy, na.rm = TRUE),
  `Q1 single dose (Gy)` = quantile(single_dose_gy, 0.25, na.rm = TRUE),
  `Q3 single dose (Gy)` = quantile(single_dose_gy, 0.75, na.rm = TRUE),
  Min = min(single_dose_gy, na.rm = TRUE),
  Max = max(single_dose_gy, na.rm = TRUE),
  `Most common single dose (Gy)` = {
    v <- single_dose_gy[is.finite(single_dose_gy)]
    if (length(v) == 0) NA_real_ else as.numeric(names(sort(table(round(v, 1)), decreasing = TRUE)[1]))
  }
), by = Model][order(factor(Model, levels = c("Cell line", "Mouse/Animal", "Patient/clinical", "Unspecified")))]

dose_by_particle <- dose_dist[, .(
  `N papers` = .N,
  `Median (Gy)` = median(single_dose_gy, na.rm = TRUE),
  `Q1 (Gy)` = quantile(single_dose_gy, 0.25, na.rm = TRUE),
  `Q3 (Gy)` = quantile(single_dose_gy, 0.75, na.rm = TRUE)
), by = Particle][order(-`N papers`, Particle)]

factor_order <- df[, .(n = .N), by = Factor][order(-n)][1:min(30, .N)]$Factor
dose_by_factor <- dose_dist[Factor %in% factor_order, .(
  `Papers (total)` = df[Factor == .BY$Factor, .N],
  `Papers (with parsable dose)` = .N,
  `Median dose (Gy)` = median(single_dose_gy, na.rm = TRUE),
  `Q1 (Gy)` = quantile(single_dose_gy, 0.25, na.rm = TRUE),
  `Q3 (Gy)` = quantile(single_dose_gy, 0.75, na.rm = TRUE),
  Min = min(single_dose_gy, na.rm = TRUE),
  Max = max(single_dose_gy, na.rm = TRUE)
), by = Factor][order(match(Factor, factor_order))]

dose_distribution_out <- dose_dist[, .(
  `Single dose (Gy)` = single_dose_gy,
  `Total dose (Gy)` = total_dose_gy,
  Fractions = fractions,
  `Dose kind` = dose_kind,
  Model,
  `Particle category`,
  `Cancer type`,
  DOI,
  Year
)]

fwrite(modality_counts, file.path(root, "dados", "equipment_dose", "modality_counts.csv"))
fwrite(device_counts, file.path(root, "dados", "equipment_dose", "device_counts.csv"))
fwrite(dose_by_model, file.path(root, "dados", "equipment_dose", "dose_by_model.csv"))
fwrite(dose_by_particle, file.path(root, "dados", "equipment_dose", "dose_by_particle.csv"))
fwrite(dose_by_factor, file.path(root, "dados", "equipment_dose", "dose_by_factor.csv"))
fwrite(dose_distribution_out, file.path(root, "dados", "equipment_dose", "dose_distribution.csv"))
fwrite(particle_modality_crosstab, file.path(root, "dados", "equipment_dose", "particle_modality_crosstab.csv"))

# -----------------------------
# Network pack
# -----------------------------

paper_factor <- unique(df[, .(doc_id, Factor, strong_flag)])
factor_stats <- paper_factor[, .(
  papers = .N,
  strong_papers = sum(strong_flag, na.rm = TRUE)
), by = Factor]

cat_map <- df[, .N, by = .(Factor, category = `Factor type`)][order(Factor, -N)]
cat_map <- cat_map[, .SD[1], by = Factor][, .(Factor, category)]

refine_map <- df[, .(
  refined_classification = paste(sort(unique(split_multi(`Direction labels (n)`))), collapse = "; ")
), by = Factor]

paper_list <- split(paper_factor$Factor, paper_factor$doc_id)
paper_list <- lapply(paper_list, unique)
paper_list <- paper_list[lengths(paper_list) >= 2]

edge_acc <- list()
if (length(paper_list) > 0) {
  for (fset in paper_list) {
    cmb <- t(combn(sort(fset), 2))
    if (is.null(dim(cmb))) next
    k <- paste(cmb[, 1], cmb[, 2], sep = "||")
    edge_acc[[length(edge_acc) + 1]] <- data.table(edge_key = k)
  }
}

if (length(edge_acc) > 0) {
  edge_dt <- rbindlist(edge_acc)
  edges <- edge_dt[, .(weight = .N), by = .(edge_key)]
  edges[, c("source", "target") := tstrsplit(edge_key, "\\|\\|", perl = TRUE)]
  edges[, edge_key := NULL]
} else {
  edges <- data.table(source = character(0), target = character(0), weight = integer(0))
}

if (nrow(edges) > 0) {
  total_docs <- uniqueN(paper_factor$doc_id)
  f_papers <- setNames(factor_stats$papers, factor_stats$Factor)
  edges[, papers_A := f_papers[source]]
  edges[, papers_B := f_papers[target]]
  edges[, jaccard := round(weight / (papers_A + papers_B - weight), 4)]
  edges[, p_ab := weight / total_docs]
  edges[, p_a := papers_A / total_docs]
  edges[, p_b := papers_B / total_docs]
  edges[, pmi := round(log2(pmax(p_ab, 1e-9) / pmax(p_a * p_b, 1e-9)), 4)]
  edges[, conditional_BgivenA := round(weight / papers_A, 4)]
  edges[, conditional_AgivenB := round(weight / papers_B, 4)]

  strong_map <- paper_factor[strong_flag == TRUE, .(doc_id, Factor)]
  strong_pair <- merge(
    strong_map[, .(doc_id, source = Factor)],
    strong_map[, .(doc_id, target = Factor)],
    by = "doc_id",
    allow.cartesian = TRUE
  )[source < target]
  strong_pair <- strong_pair[, .(strong_both = .N), by = .(source, target)]
  edges <- merge(edges, strong_pair, by = c("source", "target"), all.x = TRUE)
  edges[is.na(strong_both), strong_both := 0L]
  setcolorder(edges, c("source", "target", "weight", "jaccard", "pmi", "conditional_BgivenA", "conditional_AgivenB", "strong_both", "papers_A", "papers_B"))
  edges <- edges[order(-weight, source, target)]
}

nodes <- merge(factor_stats, cat_map, by = "Factor", all.x = TRUE)
nodes <- merge(nodes, refine_map, by = "Factor", all.x = TRUE)

community <- rep(0L, nrow(nodes))
if (nrow(edges) > 0 && requireNamespace("igraph", quietly = TRUE)) {
  g <- igraph::graph_from_data_frame(edges[, .(source, target, weight)], directed = FALSE, vertices = nodes$Factor)
  cl <- igraph::cluster_louvain(g, weights = igraph::E(g)$weight)
  community <- as.integer(cl$membership[match(nodes$Factor, names(cl$membership))])
  community[is.na(community)] <- 0L
}

nodes[, community := community]
setnames(nodes, c("Factor", "category"), c("factor", "category"))
nodes <- nodes[, .(factor, papers, strong_papers, category, refined_classification, community)][order(-papers, factor)]

communities <- nodes[, .(
  n_factors = .N,
  total_papers = sum(papers),
  top_factors = paste(head(factor[order(-papers)], 10), collapse = "; ")
), by = community][order(community)]

network_json <- list(
  nodes = lapply(seq_len(nrow(nodes)), function(i) {
    list(
      id = nodes$factor[i],
      papers = unname(nodes$papers[i]),
      strong_papers = unname(nodes$strong_papers[i]),
      category = nodes$category[i],
      refined_classification = nodes$refined_classification[i],
      community = unname(nodes$community[i])
    )
  }),
  edges = lapply(seq_len(nrow(edges)), function(i) {
    list(
      source = edges$source[i],
      target = edges$target[i],
      weight = unname(edges$weight[i]),
      jaccard = unname(edges$jaccard[i]),
      pmi = unname(edges$pmi[i])
    )
  })
)

fwrite(nodes, file.path(root, "dados", "network", "nodes.csv"))
fwrite(edges, file.path(root, "dados", "network", "edges.csv"))
fwrite(communities, file.path(root, "dados", "network", "communities.csv"))
write_json(network_json, file.path(root, "dados", "network", "network.json"), auto_unbox = TRUE, pretty = TRUE)

# -----------------------------
# Knowledge graph pack
# -----------------------------

top_papers <- function(v, n = 3) {
  v <- unique(trimws(as.character(v)))
  v <- v[!is.na(v) & v != ""]
  if (length(v) == 0) return("")
  paste(head(v, n), collapse = "; ")
}

triples <- list()

# Factor -> Category
t1 <- df[, .(evidence_count = .N, sample_papers = top_papers(DOI)), by = .(subject = Factor, object = `Factor type`)]
t1[, `:=`(subject_type = "Factor", predicate = "belongs_to_category", object_type = "BiologicalCategory")]
triples[[length(triples) + 1]] <- t1

# Factor -> Cancer
fc <- df[, .(Cancer = split_multi(`Cancer type`)), by = .(row_id, Factor, DOI)]
fc <- fc[Cancer != "" & !is.na(Cancer) & !Cancer %in% c("(Unknown)", "Unknown")]
t2 <- fc[, .(evidence_count = .N, sample_papers = top_papers(DOI)), by = .(subject = Factor, object = Cancer)]
t2[, `:=`(subject_type = "Factor", predicate = "associated_with_cancer", object_type = "Cancer")]
triples[[length(triples) + 1]] <- t2

# Factor -> Particle
fp <- df[, .(Particle = split_multi(`Particle type`)), by = .(row_id, Factor, DOI)]
fp <- fp[Particle != "" & !is.na(Particle) & !Particle %in% c("(none)", "(Unknown)", "Unknown")]
t3 <- fp[, .(evidence_count = .N, sample_papers = top_papers(DOI)), by = .(subject = Factor, object = Particle)]
t3[, `:=`(subject_type = "Factor", predicate = "studied_with_particle", object_type = "Particle")]
triples[[length(triples) + 1]] <- t3

# Factor -> Modality
fm <- df[, .(Modality = split_multi(`Radiation modality`)), by = .(row_id, Factor, DOI)]
fm <- fm[Modality != "" & !is.na(Modality)]
t4 <- fm[, .(evidence_count = .N, sample_papers = top_papers(DOI)), by = .(subject = Factor, object = Modality)]
t4[, `:=`(subject_type = "Factor", predicate = "used_with_modality", object_type = "Modality")]
triples[[length(triples) + 1]] <- t4

# Factor -> Toxicity endpoint
fte <- df[, .(Endpoint = split_multi(`Toxicity endpoint`)), by = .(row_id, Factor, DOI)]
fte <- fte[Endpoint != "" & !is.na(Endpoint)]
t5 <- fte[, .(evidence_count = .N, sample_papers = top_papers(DOI)), by = .(subject = Factor, object = Endpoint)]
t5[, `:=`(subject_type = "Factor", predicate = "associated_with_toxicity_endpoint", object_type = "ToxicityEndpoint")]
triples[[length(triples) + 1]] <- t5

triples_df <- rbindlist(triples, fill = TRUE)
triples_df <- triples_df[, .(subject, subject_type, predicate, object, object_type, evidence_count, sample_papers)]
triples_df <- triples_df[order(subject_type, subject, predicate, -evidence_count, object)]

entities <- unique(rbind(
  triples_df[, .(entity_id = subject, type = subject_type)],
  triples_df[, .(entity_id = object, type = object_type)]
))
entities <- entities[order(type, entity_id)]

fwrite(triples_df, file.path(root, "dados", "knowledge_graph", "triples.csv"))
fwrite(entities, file.path(root, "dados", "knowledge_graph", "entities.csv"))

# -----------------------------
# External links pack
# -----------------------------

factor_rank <- factor_trends[, .(Factor, Total_strong)]
factor_cat <- df[, .N, by = .(Factor, `Factor type`)][order(Factor, -N)]
factor_cat <- factor_cat[, .SD[1], by = Factor][, .(Factor, `Biological category` = `Factor type`)]

ext <- merge(factor_cat, factor_rank, by = "Factor", all = TRUE)
ext <- ext[order(-Total_strong, Factor)]
ext[, `Gene symbol (if applicable)` := vapply(Factor, parse_gene_symbol, character(1))]

mk_url <- function(base, q) ifelse(q == "", "", paste0(base, URLencode(q, reserved = TRUE)))

ext[, `NCBI Gene` := mk_url("https://www.ncbi.nlm.nih.gov/gene/?term=", paste0(`Gene symbol (if applicable)`, "[Gene Symbol] AND human[Organism]"))]
ext[, `UniProt` := mk_url("https://www.uniprot.org/uniprotkb?query=", paste0(`Gene symbol (if applicable)`, " AND organism_id:9606"))]
ext[, `STRING (PPI)` := mk_url("https://string-db.org/cgi/network?identifier=", `Gene symbol (if applicable)`)]
ext[, `STRING (PPI)` := ifelse(`Gene symbol (if applicable)` == "", "", paste0(`STRING (PPI)`, "&species=9606"))]
ext[, `GeneCards` := mk_url("https://www.genecards.org/cgi-bin/carddisp.pl?gene=", `Gene symbol (if applicable)`)]
ext[, `KEGG (BRITE)` := mk_url("https://www.genome.jp/kegg-bin/search?dbkey=hsa&keywords=", `Gene symbol (if applicable)`)]
ext[, `Open Targets` := mk_url("https://platform.opentargets.org/target/search?q=", `Gene symbol (if applicable)`)]
ext[, `cBioPortal (cancer)` := mk_url("https://www.cbioportal.org/results?case_set_id=all&gene_list=", `Gene symbol (if applicable)`)]
ext[, Ensembl := mk_url("https://www.ensembl.org/Multi/Search/Results?q=", paste0(`Gene symbol (if applicable)`, ";site=ensembl"))]
ext[, `ClinicalTrials.gov` := mk_url("https://clinicaltrials.gov/search?cond=Cancer&term=", paste0(`Gene symbol (if applicable)`, " radiation"))]
ext[, COSMIC := mk_url("https://cancer.sanger.ac.uk/cosmic/gene/analysis?ln=", `Gene symbol (if applicable)`)]
ext[, `PubMed (factor + radiation)` := mk_url("https://pubmed.ncbi.nlm.nih.gov/?term=", paste0('"', Factor, '" AND (radiation OR radiotherapy)'))]
ext[, DrugBank := ""]

setcolorder(ext, c(
  "Factor", "Biological category", "Gene symbol (if applicable)", "Total_strong",
  "NCBI Gene", "UniProt", "STRING (PPI)", "GeneCards", "KEGG (BRITE)",
  "Open Targets", "cBioPortal (cancer)", "Ensembl", "ClinicalTrials.gov",
  "COSMIC", "PubMed (factor + radiation)", "DrugBank"
))
setnames(ext, "Total_strong", "Total strong")

fwrite(ext, file.path(root, "dados", "external_links", "factor_external_links.csv"))

cat("Rebuild complete.\n")
cat("Rows in master xlsx:", nrow(df), "\n")
