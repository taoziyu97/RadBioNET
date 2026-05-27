library(dplyr)
library(data.table)
library(tidyr)
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(shinycssloaders)
library(ggplot2)
library(ggthemes)
library(RColorBrewer)
library(scales)
library(plotly)
library(DT)
library(shinyjs)
library(visNetwork)
library(htmltools)
library(httr)
library(jsonlite)
cache_rds <- "dados/factor_v4_proton_therapy.rds"
cache_xlsx <- "dados/factor_v4_proton_therapy.xlsx"
if (file.exists(cache_rds)) {
  senres <- readRDS(cache_rds)
} else {
  library(readxl)
  senres <- read_excel(cache_xlsx)
}

# Replace NAs with "(Unknown)" in filter columns so no rows are silently dropped
na_cols <- c("Cancer type", "Evidence type", "Particle type")
for (col in na_cols) {
  if (col %in% names(senres)) {
    senres[[col]][is.na(senres[[col]])] <- "(Unknown)"
  }
}
if (!file.exists(cache_rds)) saveRDS(senres, cache_rds)

cancer_types     <- sort(unique(senres[["Cancer type"]]))
cancer_subtypes  <- sort(unique(senres[["Cancer subtype"]]))
particle_types   <- sort(unique(senres[["Particle type"]]))
factor_types     <- sort(unique(senres[["Factor type"]]))
evidence_types   <- sort(unique(senres[["Evidence type"]]))
directions       <- sort(unique(senres[["Direction"]]))
quality_flags    <- sort(unique(senres[["Quality flag"]]))
years            <- sort(unique(senres[["Publication year"]]))

# Multi-value column choices (split on "; ", exclude Unknown)
drop_unknown <- function(x) { setdiff(x, c("Unknown", "(Unknown)")) }
cancer_type_choices <- drop_unknown(sort(unique(unlist(strsplit(senres[["Cancer type"]], "; ")))))
evidence_type_choices <- drop_unknown(sort(unique(unlist(strsplit(senres[["Evidence type"]], "; ")))))
direction_choices <- drop_unknown(sort(unique(unlist(strsplit(senres[["Direction"]], "; ")))))
quality_flag_choices <- drop_unknown(sort(unique(unlist(strsplit(senres[["Quality flag"]], "; ")))))
factor_type_choices <- drop_unknown(sort(unique(unlist(strsplit(senres[["Factor type"]], "; ")))))
particle_type_choices <- drop_unknown(sort(unique(unlist(strsplit(senres[["Particle type"]], "; ")))))

source("functions/utils.R")
source("functions/plot_functions.R")
source("functions/llm.R")

tab_files <- list.files(path = "tabs/ui", full.names = T, recursive = T)
suppressMessages(lapply(tab_files, source))
