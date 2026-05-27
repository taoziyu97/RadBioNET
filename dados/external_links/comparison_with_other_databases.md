# How this database compares with other radiation databases

## RadAtlas (https://www.radatlas.org/)
**Focus**: Radiation-responsive genes from microarray/RNA-seq studies.
**Type**: Gene expression database — "which genes change after irradiation?"
**Scope**: ~1,500 papers, mostly cell line transcriptomics.
**Strength**: Quantitative expression changes with directionality.
**Limitation**: Few clinical / mechanism papers. No particle-type distinction.
**Complementary to us**: They focus on expression delta; we focus on functional roles.

## RadioGenomicsDB / radiogenomic databases
**Focus**: Patient-level SNP/germline variants associated with radiotherapy outcome.
**Type**: GWAS-style (REQUITE consortium).
**Scope**: ~20 published associations (very small).
**Limitation**: Only clinical genotype-phenotype data.
**Complementary to us**: They map germline → outcome; we map factor → biology.

## CGGA / TCGA (general cancer databases)
**Focus**: Multi-omics for cancer patient cohorts.
**Type**: Sample-level data (mutation, expression, survival).
**Limitation**: Radiation treatment annotation is sparse and inconsistent.
**Complementary to us**: They provide patient-level data; we provide literature-derived mechanisms.

## ClinicalTrials.gov
**Focus**: Registered trials.
**Type**: Trial metadata, not biology.
**Use as link target**: from our factor page, link to "active trials targeting this factor + radiation".

## Particle-specific databases:
- PIDE (Proton Ion Dose Effect) — proton/ion dose-response
  http://pide.gsi.de/
- ICRU Reports (various)
- PIDD (Particle Therapy Patient Registry)

**Complementary to us**: They have dose-response physical data; we have biology.

## What WE uniquely offer that none of the above does:
1. **Factor × direction × cancer × particle 4D structured queries**
2. **Time-trend analysis** showing research paradigm shifts
3. **Pair-level audit** (Likely real vs artifact) — quality-aware
4. **15,730 structured paper-factor relationships** vs <1,500 elsewhere
5. **No-API-needed knowledge graph** for re-purposing

## Recommended interoperability strategy
For each factor in our database:
- Link to **NCBI Gene** for canonical info
- Link to **UniProt** for protein details
- Link to **STRING** for protein-protein interactions
- Link to **DrugBank** for drugs (for the drug factors)
- Link to **ClinicalTrials.gov** for active trials with that factor + radiation
- Link to **cBioPortal** for tumor mutation context
- Link to **PubMed** for direct query

## "What do other databases worry about?"
Looking at the comparable databases, common concerns:
- **Data quality / curation**: most are auto-extracted, no audit
- **Coverage / completeness**: ours has 40k papers (large vs RadAtlas 1.5k)
- **Update frequency**: ours is snapshot, like most
- **Annotation depth**: we have direction labels + section filter — most don't
- **Particle granularity**: rare in existing DBs — we have it
