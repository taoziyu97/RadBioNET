## RadBioNET Data Change Audit

Audit date: 2026-06-03  
Scope: Repository-tracked data changes after introducing `dados/factor_v4_proton_therapy.xlsx`.

### 1) Version Timeline (Main Table)

| Commit | Date | File(s) | Rows x Cols | Structural Changes | Content-Level Changes |
|---|---|---|---:|---|---|
| `9be671f` | 2026-05-27 | `dados/factor_v4_proton_therapy.xlsx` | 441 x 25 | Initial introduction of `factor_v4_proton_therapy.xlsx` | Migration away from `sensitive_resistance.*` |
| `13ac839` | 2026-05-27 | `dados/factor_v4_proton_therapy.xlsx`, `.rds` | 15657 x 26 | Added column: `Source batch` | Major corpus expansion (pilot -> full-scale) |
| `087b036` | 2026-05-28 | `dados/factor_v4_proton_therapy.xlsx` (+ analytics pack files) | 15730 x 29 | Added: `Radiation particle category`, `Particle type`, `Particle evidence level`, `Radiation modality`, `Particle-specific verdict`; Removed: `Radiation type`, `Pair verdict` | Net +73 rows; representation shifted from coarse radiation fields to particle-specific schema |
| `d629b66` | 2026-06-02 | `dados/factor_v4_proton_therapy.xlsx`, `.rds` | 15730 x 30 | Added column: `Toxicity endpoint` | Toxicity endpoint annotations added for 2,123 records with 15 categories |

### 2) Row-Level Change Characterization

Comparison window: `13ac839` -> `087b036` (first large schema refactor).

- Normalized key used for continuity check: `Factor + Title` (case/space normalized).
- Unique normalized keys overlap: 15,540 in both versions (no key-family disappearance).
- Multiplicity changed for 261 keys.
- Net row change: +73.
- Decomposition:
  - Added by multiplicity increase: +171 rows
  - Removed by multiplicity decrease: -98 rows

Interpretation: this interval reflects simultaneous supplementation + duplication rebalance, not pure append.

### 3) Field-Level Schema Audit

#### 3.1 Added fields

| Field | Introduced in | Type/Role | Why it matters |
|---|---|---|---|
| `Source batch` | `13ac839` | Provenance/traceability | Supports batch-level source tracking and curation reproducibility |
| `Radiation particle category` | `087b036` | Particle taxonomy | Enables grouping by particle family |
| `Particle type` | `087b036` | Particle granularity | Enables exact particle filtering and stratified analyses |
| `Particle evidence level` | `087b036` | Confidence/evidence | Supports credibility-aware analytics |
| `Radiation modality` | `087b036` | Treatment modality | Distinguishes delivery/modality context |
| `Particle-specific verdict` | `087b036` | Particle-context conclusion | Captures conclusions conditioned on particle context |
| `Toxicity endpoint` | `d629b66` | Multi-label outcome endpoint | Enables toxicity endpoint filtering and endpoint-distribution analysis |

#### 3.2 Removed/replaced fields

| Removed field | Removed in | Replacement |
|---|---|---|
| `Radiation type` | `087b036` | Split into `Radiation particle category` + `Particle type` + `Radiation modality` |
| `Pair verdict` | `087b036` | Replaced by `Particle-specific verdict` |

### 4) Missingness and Unknown Encoding Audit

Monitored columns: `Cancer type`, `Evidence type`, `Particle type`, `Radiation dose`, `Radiation platform/device`.

#### 4.1 Snapshot by version

| Version | Cancer type | Evidence type | Particle type | Radiation dose | Radiation platform/device |
|---|---:|---:|---:|---:|---:|
| `9be671f` (NA count) | 132 | 0 | n/a | 299 | 398 |
| `13ac839` (NA count) | 3880 | 4809 | n/a | 12898 | 15579 |
| `087b036` (NA count) | 3889 | 5345 | 0 | 12943 | 15698 |
| `d629b66` (NA count) | 0 | 0 | 0 | 12943 | 15698 |
| `d629b66` (`(Unknown)` count) | 3889 | 5345 | 0 | 0 | 0 |

Interpretation:
- `Cancer type` and `Evidence type` missing values were made explicit as `(Unknown)` in latest data state.
- Dose/device fields still contain substantial NA (not coerced to `(Unknown)` in source table).

### 5) Toxicity Endpoint Annotation Audit (`d629b66`)

- Records with non-empty `Toxicity endpoint`: 2,123
- Distinct endpoint categories: 15
- Total labels assigned: 2,337
- Average labels per annotated record: 1.101

#### 5.1 Category frequency

| Toxicity endpoint | Count |
|---|---:|
| Rectal / GI | 814 |
| Dermatitis / Skin | 433 |
| Necrosis | 406 |
| Hematologic | 149 |
| Fibrosis | 138 |
| Bladder / GU | 133 |
| Mucositis / Oral | 70 |
| Pneumonitis / Pulmonary | 67 |
| Cardiac / Heart | 32 |
| Fatigue / Constitutional | 28 |
| Esophagitis / Dysphagia | 17 |
| Neurologic / CNS | 16 |
| Hepatic / Liver | 14 |
| Nausea / Vomiting | 10 |
| Renal / Kidney | 10 |

### 6) Data Product Expansion Beyond Main XLSX

Introduced with `087b036` under `dados/`:

- `equipment_dose/*.csv` (modality/device/dose distributions and cross-tab)
- `trends/*.csv` (time-series, growth, era distributions)
- `network/*` (nodes, edges, communities, network JSON)
- `knowledge_graph/*` (entities, triples, schema, query examples)
- `external_links/*` (cross-database mapping and comparison notes)
- `analytics_data_pack_README.md`

Interpretation: analytics pages rely on precomputed datasets, not only on on-the-fly computation from the main table.

### 7) Runtime/Data-Interface Policies (Code-Coupled)

Code-coupled behaviors that affect data presentation/interpretation:

- `global.R`: NA-to-`(Unknown)` safeguard for filter columns (`Cancer type`, `Evidence type`, `Particle type`).
- `global.R`: `check.names = TRUE` for all analytics CSV `fread` loads (column safety for spaces/parentheses).
- `tabs/server/data.R`: filter semantics changed to "empty selection = show all" and exact matching when selected.
- `tabs/server/data.R`: cancer-type count card now splits semicolon-separated values before uniqueness counting.
- `tabs/server/analysis.R`: toxicity endpoint distribution chart generated from the new field.

### 8) Files Audited

- `dados/factor_v4_proton_therapy.xlsx`
- `dados/factor_v4_proton_therapy.rds`
- `dados/equipment_dose/*`
- `dados/trends/*`
- `dados/network/*`
- `dados/knowledge_graph/*`
- `dados/external_links/*`
- `global.R`
- `tabs/server/data.R`
- `tabs/server/analysis.R`
