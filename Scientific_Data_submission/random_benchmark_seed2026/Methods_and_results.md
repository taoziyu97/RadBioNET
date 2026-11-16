# Seed 2026 benchmark of radiation response relation extraction

## Methods

### Task specific candidate pools

We used the archived PubMed corpus to construct a benchmark of radiation-response relation extraction from titles and abstracts. We retained 8,574 PMIDs with one nonempty title block and one nonempty abstract block per publication. We excluded the 20 publications used in the earlier model and prompt experiments, leaving 8,554 PMIDs for prescreening. We applied fixed case-insensitive lexical rules to flag candidate publications for four task types. The irradiation-arm task used separate photon, proton and carbon-ion pools, and the unsupported-request task used separate missing-dose and missing-comparison pools. Pool membership could overlap.

| Task or subpool | Rule used to flag candidates before randomisation | PMIDs | Model-selection quota | Development quota |
| --- | --- | ---: | ---: | ---: |
| Factor role | Radiation, a manipulation cue such as inhibition or knockdown, a molecular cue and a radiobiological endpoint | 3,747 | 2 | 4 |
| Outcome interpretation | Radiation, an outcome cue such as a significant change, no significant difference or a descriptive median dose, plus a radiobiological endpoint, toxicity or dose cue | 888 | 2 | 4 |
| Photon arm | An explicit X-ray, photon or gamma-ray term and a numerical dose cue | 376 | 1 | 2 |
| Proton arm | An explicit proton term and a numerical dose cue | 57 | 1 | 1 |
| Carbon-ion arm | An explicit carbon-ion term and a numerical dose cue | 31 | 1 | 1 |
| Unsupported dose request | A proton or carbon-ion term without a numerical Gy, cGy or RBE cue in the title or abstract | 174 | 1 | 1 |
| Unsupported comparison request | A proton term, a clinical study-design cue and a toxicity cue | 40 | 1 | 1 |

### Randomisation and source verification

We sorted each prescreened pool by numeric PMID and generated a random permutation without replacement with a single Python 3.14.4 random generator initialised with seed 2026. We generated the model-selection orders first and the development orders second, following the pool order shown in the table. Before model inference, we reviewed candidates in the fixed draw order and took the first eligible records until each quota was reached. Once selected, a PMID was ineligible for all remaining tasks, yielding one task per publication and no overlap between sets. We recorded draw ranks and reasons for exclusion.

The source check required a reported contrast or observation for factor-role and outcome tasks, and evidence linking the exposure or outcome to a delivered irradiation arm for irradiation-arm tasks. For missing-dose tasks, the source had to discuss the relevant modality without reporting the requested delivered dose. For missing-comparison tasks, the source had to report clinical toxicity in a proton-treated cohort without reporting the requested comparison with a photon-treated cohort. The benchmark included two cases in each set whose reference was an empty record list.

An AI assistant reviewed the sampled source blocks and drafted the task scopes, reference relations and required evidence phrases before model inference. The source block identifiers, SHA-256 digests, ranked candidate pools, eligibility decisions and reference annotations were frozen and archived. Each reference evidence phrase and reported reference dose was checked against the original text. The reference annotations are provisional and await independent human review.

### Model comparison and scoring

We evaluated Llama 3.3 70B Instruct, Qwen3.5-27B, GPT-OSS 20B, DeepSeek V4.1 Flash 1017 and Claude Opus 5.5 via the OpenRouter chat-completions API. For each task, all models received the same title, abstract, extraction scope, clarified zero-shot instructions and output schema, with a generation limit of 3,000 tokens. Qwen and DeepSeek ran with reasoning disabled. GPT-OSS and Claude used low reasoning effort. Llama used the provider default. We requested a temperature of zero where supported. The random seed controlled candidate sampling.

We used one-to-one matching to compare predicted and reference relations within each task. A match required agreement on the task-specific reference fields, occurrence of the quoted evidence and any returned dose string in the archived source after normalisation, and coverage of the prespecified evidence phrases. Unmatched predictions and references counted as false positives and false negatives, respectively. We computed micro-averaged precision, recall and F1 separately for the development and model-selection sets. A task was fully matched when its predictions and references matched exactly in number and there were no unmatched relations. A valid empty response matched a task with no reference relation. An invalid response contributed no usable predicted relations and did not qualify as a fully matched task. We ranked models by strict relation-level micro-F1 on the model-selection set, using the number of fully matched tasks to break ties.

## Technical validation

We screened 28 randomly ordered candidates and retained 23 publications. The development set contained 14 tasks with 13 reference relations, and the model-selection set contained nine tasks with seven reference relations. All 115 requests returned responses. Of these, 111 conformed to the output schema. Three Qwen responses had an invalid top-level structure, and one Llama response was truncated. Claude Opus 5.5 ranked first in both sets, with strict micro-F1 scores of 92.3% in development and 85.7% in model selection. On the model-selection set, it matched six of seven reference relations and fully matched eight of nine tasks. The remaining case assigned photon irradiation to the FGFR1 finding when the title and abstract reported ionising radiation without identifying the modality (PMID 25188816). The results support using Claude Opus 5.5 to generate candidate relations for curator review. This benchmark used specified extraction tasks and provisional abstract-based references.

## Reproduction and figure inputs

Run these commands from the project root.

```sh
python3 -m scripts.radbionet_v2.random_benchmark --screen
python3 -m scripts.radbionet_v2.random_benchmark --freeze
python3 -m scripts.radbionet_v2.model_comparison --profile clarified --run \
  --reference Scientific_Data_submission/random_benchmark_seed2026/selection_reference.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --output Scientific_Data_submission/random_benchmark_seed2026/selection_run
python3 -m scripts.radbionet_v2.model_comparison --profile clarified --run \
  --reference Scientific_Data_submission/random_benchmark_seed2026/development_reference.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --output Scientific_Data_submission/random_benchmark_seed2026/development_run
python3 -m scripts.radbionet_v2.export_random_benchmark
Rscript scripts/radbionet_v2/plot_random_benchmark.R Scientific_Data_submission/random_benchmark_seed2026
```

- `candidate_draw_order.csv` and `screening_flow.csv` retain the ranked candidate PMIDs and the decisions for the reviewed prefix of each pool.
- `model_metrics.csv` has one row per model and set. `task_scores.csv` has one row per model and task. `task_type_metrics.csv` has one row per model, set and task type. Precision, recall and F1 are proportions. Undefined denominators are blank. Read PMIDs as identifiers when joining to other files.
- Each run folder contains the request configuration, returned model and provider, completion IDs, raw outputs and relation-level scores. Costs are recorded in US dollars as returned by the API.
