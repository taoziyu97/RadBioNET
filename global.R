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
na_cols <- c("Cancer type", "Radiation type", "Evidence type")
for (col in na_cols) {
  senres[[col]][is.na(senres[[col]])] <- "(Unknown)"
}
if (!file.exists(cache_rds)) saveRDS(senres, cache_rds)

cancer_types     <- sort(unique(senres[["Cancer type"]]))
cancer_subtypes  <- sort(unique(senres[["Cancer subtype"]]))
radiation_types  <- sort(unique(senres[["Radiation type"]]))
factor_types     <- sort(unique(senres[["Factor type"]]))
evidence_types   <- sort(unique(senres[["Evidence type"]]))
directions       <- sort(unique(senres[["Direction"]]))
quality_flags    <- sort(unique(senres[["Quality flag"]]))
years            <- sort(unique(senres[["Publication year"]]))

source("functions/utils.R")
source("functions/plot_functions.R")
source("functions/llm.R")

tab_files <- list.files(path = "tabs/ui", full.names = T, recursive = T)
suppressMessages(lapply(tab_files, source))
