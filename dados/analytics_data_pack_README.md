# Analytics Data Pack
Pre-computed analysis files from the radiation biology MASTER v2 database.
All files are plain CSV/JSON/TXT, ready to feed into plotting libraries (Plotly,
D3.js, Recharts, Cytoscape.js, etc) without any further computation.

## Folders

### network/
Factor × Factor co-occurrence network
- nodes.csv: 159 factors with paper count, category, community ID
- edges.csv: 1,367 edges with weight, Jaccard, PMI, conditional probabilities
- network.json: Cytoscape.js / D3.js compatible format
- communities.csv: 8 detected functional clusters

### trends/
Time-trend analysis (per-factor over years)
- timeline_per_factor.csv: factor × year long format (2,524 rows)
- factor_trends.csv: per-factor metrics (slope, p-value, era totals, hot/cool tag)
- hot_factors.csv: 10 factors with ≥3x recent acceleration (STING, cGAS, GSDME, etc)
- top_growth_factors.csv: top 20 by absolute recent growth
- era_distribution.csv: for stacked area / radar
- overall_papers_per_year.csv: corpus-wide baseline

### equipment_dose/
Equipment, modality, and dose statistics
- modality_counts.csv: IMRT/SBRT/FLASH/Brachytherapy/BNCT/etc paper counts
- particle_modality_crosstab.csv: particle × modality matrix
- device_counts.csv: LINAC/Cyclotron/Synchrotron/TrueBeam/60Co etc
- dose_by_model.csv: typical doses for cell line / mouse / patient studies
- dose_by_particle.csv: typical doses per particle type (Photon median 5 Gy, Proton 15 Gy, Carbon 4 Gy)
- dose_by_factor.csv: typical doses studied for top 30 factors
- dose_distribution.csv: 16,606 parsed dose entries (full data for histogram)

### knowledge_graph/
RDF-style triples (subject, predicate, object, evidence_count, sample_papers)
- triples.csv: 1,419 triples across 12 predicate types
- entities.csv: 248 entities (Factor / Cancer / Particle / Modality / BiologicalCategory)
- schema.txt: predicate definitions
- example_queries.md: query examples

### external_links/
Pre-built URLs to external databases (no API call needed)
- factor_external_links.csv: 184 factors × 12 link types (NCBI Gene, UniProt,
  STRING, GeneCards, KEGG, Open Targets, cBioPortal, ClinicalTrials.gov, COSMIC,
  DrugBank, PubMed)
- comparison_with_other_databases.md: how this DB compares to RadAtlas,
  radiogenomic DBs, TCGA, etc.

## Total
~25 ready-to-use data files, all derived from the MASTER v2 dataset.
No further computation needed for visualization.
