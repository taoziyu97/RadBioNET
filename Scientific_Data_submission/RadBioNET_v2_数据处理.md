# RadBioNET v2 数据整理与复跑

这次输出是基于现有归档和 PubMed 接口试跑的候选数据。它用于启动筛选和标注。正式检索仍需按照正文所述完成查询校准并冻结检索日期。双人筛选、关系标注和独立抽样准确率需要根据后续真实审核记录计算。

## 先打开这些文件

| 文件 | 用途 |
|---|---|
| [summary.json](data_v2_prepared/summary.json) | 本次实际处理量、连接规则、剂量解析状态和风险标记计数。 |
| [legacy_rows.csv](data_v2_prepared/legacy_rows.csv) | 保留工作簿各列，附原行号、稳定 ID、回填 PMID 和连接依据。 |
| [calibration_review_queue.csv](data_v2_prepared/calibration_review_queue.csv) | 固定种子抽出的候选校准清单。可用来试填标注表。 |
| [review_queue.csv](data_v2_prepared/review_queue.csv) | 全量待审候选与 PMID、DOI、题名和优先标记。 |
| [dose_mentions.csv](data_v2_prepared/dose_mentions.csv) | 去重后的原始剂量表达、标准化单位、上下界、分次数、计算量和归属状态。 |
| [targeted_source_checks.csv](data_v2_prepared/targeted_source_checks.csv) | 已复核的原文案例和具体位置，含区分 X 射线分割、质子剂量条件和平均心脏剂量的记录。 |
| [reviewer_form.csv](data_v2_prepared/reviewer_form.csv) 与 [screening_form.csv](data_v2_prepared/screening_form.csv) | 复制给两位审阅者各自填写。 |
| [search_runs.csv](data_v2_prepared/search_runs.csv) | 各历史导出文件的计数及真实试跑的检索式、翻译、时间与命中数。 |

候选的粒子字段是历史提示。同一论文、因素、候选方向和粒子提示的重复证据共用一个候选 ID。每个候选可在审核中拆分成多个具体发现。不同来源的匹配记录通过候选 ID 连接。字符位置用 0 起算的半开区间表示，作用于带哈希的来源文本块。带全文摘要或证据摘录的文件仅用于本地标注。仓储公开范围需依据来源使用条件确定。

剂量表里，脚本解析的普通剂量仍保持未归属状态。带暴露条件证据的特定原文案例由 dose_ids 连到已核对的原文表。这里的案例级暴露条件与最终关系表的实验臂 ID 对应的是不同阶段。单一剂量值保持其原始量纲和未知剂量角色。只有明确的分割表达才导出总量或单次量，Gy(RBE) 保持单独的量纲。范围不填中点。剂量字段无值时保留空白。

## 复跑

从仓库根目录运行。使用 Python 3.11 或以上，安装 scripts/radbionet_v2/requirements.txt。将已有输出目录换成新的版本名，保留当时的审核文件和输入哈希。

```sh
python3 -m pip install -r scripts/radbionet_v2/requirements.txt
archive='../2025/放疗数据库'
python3 -m scripts.radbionet_v2.build \
  --workbook dados/factor_v4_proton_therapy.xlsx \
  --general "$archive"/除了质子以外的/pubmed_nbib/*.nbib \
  --proton "$archive"/质子单独放在这里/*.nbib \
  --direction-audit "$archive/除了质子以外的/proton_therapy_FACTOR_REFINED_MASTER_v2.xlsx" \
  --capture Scientific_Data_submission/data_v2_pubmed_pilot \
  --scan-archive --output /tmp/radbionet-prepared-rebuild
python3 -m unittest scripts.radbionet_v2.test_pipeline
```

正式检索时，先校准并保存实际使用的查询文件。提供实际截止日后，以下命令会保存 PMID、检索翻译、日期分段、Efetch XML 和哈希。NCBI_EMAIL 和 NCBI_API_KEY 通过环境变量传入。单日超过 PubMed API 的上限时，按脚本报错提示用 EDirect 对该区间单独归档。

```sh
python3 -m scripts.radbionet_v2.pubmed \
  --query-file Scientific_Data_submission/RadBioNET_v2_PubMed_searches.txt \
  --start 2000-01-01 --end YYYY-MM-DD --mode production \
  --output Scientific_Data_submission/data_v2_pubmed_production
```

## 开放全文清单和下载

全文清单以历史 NBIB 的 PMID 为范围，用 PMC 的 Open Access Subset 检索过滤掉仍处于禁运期的记录，再与 PMC Cloud 的版本清单核对。云端清单缺少的匹配项通过 OAI-PMH 的 `ListMetadataFormats` 核对是否提供全文 XML。统计单位为唯一 PMID。清单中的 `legacy` 对应初版标注表回连的 PMID，`historical` 对应全部历史 NBIB 的唯一 PMID。重新查找时指定新的输出目录，可保留历次核对结果。

```sh
python3 -m scripts.radbionet_v2.pmc_fulltext check \
  --prepared Scientific_Data_submission/data_v2_prepared \
  --output Scientific_Data_submission/pmc_fulltext_inventory
```

稍后可按下面的命令下载。保留 `--limit 5` 先试跑，确认后删除该参数下载 `legacy` 范围的全部 XML。要下载全部历史语料中的开放全文，改用 `--cohort historical`。

```sh
python3 -m scripts.radbionet_v2.pmc_fulltext download \
  --plan Scientific_Data_submission/pmc_fulltext_inventory/download_plan.csv \
  --cohort legacy --limit 5 \
  --output Scientific_Data_submission/pmc_fulltext_downloads
```

下载脚本根据清单选择 PMC Cloud 或 OAI-PMH。Cloud 文件按官方 MD5 校验并记录版本和许可。OAI-PMH 文件记录源响应的 SHA-256、记录日期和许可字段。两种渠道都检查正文结构，保存下载时间及 XML 的 SHA-256。重复运行时校验并跳过已经下载的文件。下载失败的 PMID 和原因写入 `last_download.json`。

## 五种模型的抽取评估

候选模型为 Llama 3.3 70B Instruct、Qwen3.5-27B、GPT-OSS 20B、DeepSeek V4.1 Flash 1017 和 Claude Opus 5.5。开发集有 14 项任务，来自 11 篇文献，包含 17 条参考关系。留出集有 9 项任务，来自另外 9 篇文献，包含 10 条参考关系。两份参考文件记录 PMID、归档题名和摘要的文本块哈希、抽取范围和待独立复核的参考记录。各模型在同一轮收到相同的任务说明、来源文本和 JSON schema。参考记录留在本地评分。

在项目根目录执行以下命令。脚本从 `OPENROUTER_API_KEY` 或本机的 `~/.config/radbionet/openrouter.key` 读取密钥。每项任务保存服务返回的模型标识、推理服务商、时间、费用和输出。相同目录在配置一致时可续跑，已收到的有效或格式无效响应均纳入评估，服务错误可重试。

```sh
python3 -m scripts.radbionet_v2.model_comparison --run \
  --reference Scientific_Data_submission/RadBioNET_model_benchmark_cases.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --output Scientific_Data_submission/model_comparison_five_development
```

`comparison.json` 汇总各模型完成的任务数、按整条关系评分的微平均精确率、召回率、F1 和逐任务结果。预测关系要与参考字段一一匹配，其剂量和证据引文经规定的规范化后须能在输入中定位，证据还须覆盖预设短语。收到无效 JSON 时，该任务计为无可用预测，记录无效输出状态。服务拒绝的任务记为未完成，单列于状态统计。推理设置随结果保存在 `run_manifest.json`。Qwen 和 DeepSeek 关闭推理，GPT-OSS 和 Claude 使用低推理强度。每项任务的默认生成上限为 3,000 token。Claude 的端点使用服务默认采样设置，其余请求的温度设为 0。

独立于先导文献的复测使用下面的命令。先导阶段识别出的方向与对照判定歧义，已在复测提示中明确。复测参考文件中的 PMID 与首轮无重叠。

```sh
python3 -m scripts.radbionet_v2.model_comparison --run --profile clarified \
  --reference Scientific_Data_submission/RadBioNET_model_holdout_cases.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --output Scientific_Data_submission/model_comparison_five_holdout
```

两份任务汇总分别报告。最终按留出集的严格关系级 F1 选定后续候选抽取模型。F1 并列时比较整项任务完全匹配数。五个模型完成所有留出任务后，脚本才给出五模型排名第一的候选。入库前仍需依据原文逐条核验。

2026 年 11 月 16 日完成了五个模型对全部 23 项任务的评估，共收到 115 份符合 schema 的输出。以下分数均为严格关系级微平均指标。

| 模型 | 开发集 F1 | 留出集精确率 | 留出集召回率 | 留出集 F1 | 留出集完全匹配任务 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Llama 3.3 70B Instruct | 9.5% | 15.4% | 20.0% | 17.4% | 1/9 |
| Qwen3.5-27B | 17.6% | 27.3% | 30.0% | 28.6% | 3/9 |
| GPT-OSS 20B | 30.3% | 10.0% | 10.0% | 10.0% | 2/9 |
| DeepSeek V4.1 Flash 1017 | 34.3% | 27.3% | 30.0% | 28.6% | 3/9 |
| Claude Opus 5.5 | 58.8% | 100.0% | 100.0% | 100.0% | 9/9 |

根据该结果，后续候选抽取选用 `anthropic/claude-opus-5.5`。评估中的 Claude 请求使用低推理强度和 3,000 token 的生成上限，接口实际路由到 Claude Platform on AWS。Claude 在开发集匹配了 17 条参考关系中的 10 条，在留出集匹配了 10 条参考关系中的 10 条。两组均为指定抽取范围的挑战任务，参考记录待独立复核。全文抽取与正式发布数据的质量需要分别验证。

### 提示策略开发实验

固定 Claude Opus 5.5、Claude Platform on AWS、低推理强度、3,000 token 生成上限和第二版 schema，在同一开发集的 14 项任务上使用四种提示。四种设置均以澄清版提示为基础。两个实验因素是三条合成示例与输出前证据核对指令。示例覆盖照射组剂量分别归属、药物靶点识别，以及原文未给出该照射组剂量时返回空数组。证据核对要求逐条检查因素角色、剂量和射线归属、对照、结果方向及引文位置。各设置均只返回最终 JSON。

```sh
python3 -m scripts.radbionet_v2.prompt_comparison \
  --reference Scientific_Data_submission/RadBioNET_model_benchmark_cases.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --output Scientific_Data_submission/prompt_comparison_development
```

| 提示设置 | 严格关系 F1 | 完全匹配任务 | 保留字段和原文定位要求、移除参考证据短语要求后匹配的关系 |
| --- | ---: | ---: | ---: |
| 澄清版零样本 | 88.2% | 13/14 | 15/17 |
| 加入少样本示例 | 88.2% | 12/14 | 17/17 |
| 加入输出前证据核对 | 82.4% | 12/14 | 15/17 |
| 同时加入示例和证据核对 | 82.4% | 12/14 | 14/17 |

四种设置均完成 14 项任务，共 56 份有效响应，每种设置的 17 条输出均附有能在归档文本中定位的引文。引文能定位和引文足以支持整条关系是两项可分别核查的指标。继续以澄清版零样本提示作为工作基线。少样本在移除预设参考短语要求后匹配全部参考关系，可在独立复核中与零样本继续比较。

## 每批文献的人工抽检和版本回溯

批次抽检使用预先冻结的待处理文献清单，要求每个 PMID 只出现一次。按 PMID 数值排序后，每 200 篇组成一批。根种子为 2026，第 `i` 批使用字符串种子 `2026:i`，从组内无放回抽取 10 篇。末批不足 10 篇时全部抽取。抽样以文献为单位，包含处理成功并抽到关系的文献、返回空数组的文献，以及输出无效或调用失败的文献。脚本保存原始清单的 SHA-256、Python 版本、实际批次大小、抽样概率和抽中 PMID。

```sh
python3 -m scripts.radbionet_v2.batch_qc sample \
  --frame production_pmids.csv --seed 2026 --output batch_sample.json
```

两位审核者在看不到模型输出的情况下，分别按本次推理使用的文本和范围录入应抽取的关系。裁决后，每个抽中的 PMID 在参考 JSON 中有一条任务记录，格式与已归档的 `selection_reference.json` 一致。文献确无受支持的发现时填写 `"expected": []`。原始推理任务的 `pmid`、`source_blocks` 和 `focus` 与审核任务保持一致。全文中新增的证据记录为输入覆盖问题，另行建立包含该段全文的推理任务。

```sh
python3 -m scripts.radbionet_v2.batch_qc audit \
  --sample batch_sample.json --inference-input frozen_extraction_tasks.json \
  --reference adjudicated_audit_tasks.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --predictions candidate_run_directory --output batch_discrepancies.json
```

差异日志记录匹配、漏抽、多抽、响应状态和证据校验标志。某一参考关系只有一个同因素和终点的预测候选时，报告变化字段及人工值、模型值。多条结果具有相同因素和终点、无法可靠配对时，保留关系级未匹配计数，由人工确定字段差异。

本次实际增加 `radbionet-fact-extraction-3-arm-evidence`。每条关系新增 `beam_evidence` 和 `dose_evidence` 两个字符串字段。提示词要求用原文分别支持目标组射线和剂量。只出现一般性照射表述时使用 `unreported` 并将 `beam_evidence` 留空。原文无法将剂量归到目标组时将 `dose` 和 `dose_evidence` 留空。证据校验逐字核对规范化后的引文。对于赋值的射线，检查射线证据中是否出现对应的明确名称。对于赋值的剂量，检查剂量证据中是否含该数值及其原始单位。剂量引文出现多个射线类型、只提到其他射线类型或缺少组相关射线名称时，记录 `dose_to_arm_link_requires_review`。同一句明确写出多个组共用剂量也可能触发此标志，由审核者确认共享剂量。校验层保留原始模型值和人工裁决值。

回溯时先固定模型、输入范围、模型供应商、推理强度、输出上限和评分规则，再用新版提示词、schema 和证据校验重跑。修订只涉及局部的确定性规则时，按旧版输出的可核查条件列出受影响任务，连同能解析正确的对照案例复测。本次修订增加了两个必填证据字段，采用该 schema 的生产记录需要为这些字段生成新版输出。新版结果写入独立运行目录，记录提示词、schema、校验器版本和输入哈希。生产入库继续使用审核者确认或裁决后的记录。用于迭代修改的审核例进入回归测试，最终一致性由未参与改版的单独人工样本评估。

用实际的 Claude Opus 5 在 seed 2026 的九项已有任务上对比了旧版与新版。同一供给端和推理配置下，旧版匹配 5/7 条参考关系，新版匹配 7/7 条。旧版在 PMID 25188816 将 FGFR1 抑制标为靶点，新版改为干预因素。旧版在 PMID 41996280 将剂量写作 `total dose of 10 Gy`，新版保留数值及单位，并把上下文移入剂量证据。PMID 32974200 的三种射线共用剂量在新版匹配参考答案，同时触发人工复核标志。这次对照使用的是早先冻结的临时参考标注，适用于调试。生产批次尚无独立人工审核结果。

```sh
python3 -m scripts.radbionet_v2.batch_qc replay \
  --reference Scientific_Data_submission/random_benchmark_seed2026/selection_reference.json \
  --source Scientific_Data_submission/data_v2_prepared/local_evidence/text_blocks.csv \
  --output Scientific_Data_submission/claude_arm_evidence_replay
```

## 导入审核

筛选表填 include、exclude 或 uncertain。关系表填 accept、exclude 或 uncertain。两位审阅者的 reviewer_id 要独立。每次决策填理由与代码本版本。接受关系还需填写因素角色、实际干预或观察状态、对照、结果、时间点、效应方向和原文定位。原文未报告的时间填 not_reported。一个候选对应多个实验发现时，为每个发现提供一致的 finding_key，保留两份审阅记录。确认粒子时填写实验、照射臂和暴露来源位置。

第三人的表使用相同列结构。未解决的分歧和未完成的筛选会留在审核状态表。程序只在出版物已纳入且有两份独立判断，或两份判断经第三人裁决的情况下输出接受关系。

```sh
python3 -m scripts.radbionet_v2.adjudicate \
  --prepared Scientific_Data_submission/data_v2_prepared \
  --screening screening_reviewer1.csv --screening screening_reviewer2.csv \
  --reviews relations_reviewer1.csv --reviews relations_reviewer2.csv \
  --adjudication relation_adjudication.csv \
  --output /tmp/radbionet-reviewed-v2
```

如有筛选分歧裁决，添加 --screening-adjudication。审核后将生成出版物决策、候选决策、接受关系、照射臂、完整关系审阅日志及按来源与粒子分层的独立核验样本。候选校准样本用于训练和试标。准确性估计须依据后续冻结的接受关系样本及独立审核结果。

独立审阅者在 audit_form.csv 中逐条填 correct、incorrect 或 unverifiable，并给出判断依据。复核后用以下命令计算整条关系正确率。输出包含分层加权结果、95% 置信区间和不可核实比例。分字段准确率和漏标率仍需依据对应的审核记录另行计算。

```sh
python3 -m scripts.radbionet_v2.audit \
  --sample /tmp/radbionet-reviewed-v2/audit_sample.csv \
  --audit completed_audit.csv --output /tmp/radbionet-audit-result.json
```
