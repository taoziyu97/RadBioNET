# RadBioNET 的 Scientific Data 写作与投稿指南

**2026-11-13 更新。** 英文全文的正文围绕拟投稿版本，包含具体的筛选、证据定位、判定、剂量归因和抽样验证方法。附录 A 保留旧版 15,720 行数据的实际处理与核查。实施完成后，根据实际日志填写正文标出的日期、软件版本、纳排数、验证结果和仓储 DOI。表 1–4 对应判定规则、剂量测试、数据文件和验证报告。 [英文全文工作稿](</Users/taozy/Nutstore Files/project/RadBioNET/Scientific_Data_submission/RadBioNET_Data_Descriptor.docx>)

**建议稿型是 Data Descriptor。** 论文的对象是固定版本的放射反应文献注释、字段和证据来源。网站提供浏览入口。光子与粒子的方向比较、文献网络预测各自可以提出独立的研究问题。

## 为什么数据论文读起来繁琐

同一个字段常需交代三次，分别回答三个问题。以粒子证据层级为例，**Methods** 讲怎么标为 Direct，**Data Records** 讲去哪一个文件找该字段，**Technical Validation** 检查 Direct 是否真的指向该因素及结果对应的照射。期刊还要求 **Data Availability** 简短重述静态存档的位置。写作时让每节各回答一个问题，就能避免同一段流程讲三遍。期刊当前要求标题不超过 110 字符，建议摘要不超过 170 词。Methods 无固定字数上限，Data Overview 可选且应短。 [Scientific Data 投稿指南](https://www.nature.com/sdata/publish/submission-guidelines) · [审稿标准](https://www.nature.com/sdata/policies/for-referees)

同刊 **Article** 可以围绕数据共享、标准、整理方法等提出研究问题，常采用 Introduction、Methods、Results、Discussion。Giner-Miguelez 等（2025）研究数据论文的文档质量，用抽样和分析回答研究问题。**Data Descriptor** 围绕一份可复用数据组织文章。RadBioNET 目前最明确的贡献是有出处、方向和粒子依据的注释，适合后者。 [Article 范例](https://www.nature.com/articles/s41597-025-04402-4) · [稿型定义](https://www.nature.com/sdata/submission-guidelines)

## 定向选读

按与 RadBioNET 方法的相似度选读了 2024–2026 年的论文，并补充一篇同领域的早期 Data Descriptor。

| 论文 | 可仿照的做法 | 用到 RadBioNET 的哪一步 |
|---|---|---|
| Lai 等，EnzChemRED，2024 | 给出文献来源、关系抽取的标注单位和具体句例，单列语料构建及质量控制 | 明确 RadBioNET 的 Strong、Weak 是文本共现层级，给出候选关系形成和同文聚合的可复核例子。 [原文](https://www.nature.com/articles/s41597-024-03835-7) |
| Kramer 等，水生环境化学品效应浓度与作用方式，2024 | 写明文献整理和数据库数值的筛选、聚合规则 | 串起原始剂量字符串、解析后的数值、统计分母。注明物理剂量、加权剂量、器官受量和分割方案。 [原文](https://www.nature.com/articles/s41597-023-02904-7) |
| Xu 等，PubMed knowledge graph 2.0，2025 | 分开交代输入文献、实体与关系抽取、标准化及表格生成 | 分别报告通用放疗、质子两条线的文献去重、因子方向配对、粒子归因和表格聚合。 [原文](https://www.nature.com/articles/s41597-025-05343-8) |
| Xu 等，CrossDI，2025 | 对跨库 DOI 合并做分层抽样，单独核对年份及 PDF 来源 | 单独测文献消歧和注释准确度。对无 DOI、跨批次重复、同文多粒子分别抽查。 [原文](https://www.nature.com/articles/s41597-025-06232-w) |
| Campillos-Llanos 等，CT-EBM-SP，2026 | 分开交代文本来源、标签制作、术语规范化和一致性验证 | 将抽取规则与准确性评估写在不同节，并写出抽样分母和冲突裁决方式。 [原文](https://www.nature.com/articles/s41597-026-06608-6) |
| Polgár 等，低剂量克隆形成实验，2022 | 保留源论文及图号、剂量、细胞系和粒子信息，另做数字化验证 | 同领域写法最接近。RadBioNET 抽的是文献关系和剂量文本，宜保留原文位置并报告可核验的解析例子。 [原文](https://www.nature.com/articles/s41597-022-01653-3) |

背景优先比较 **dbCRAF 和 dbCRSR**。2024 年的 dbCRAF 做了全文筛选，也记录辐射类型、细胞系、模式生物和治疗信息。RadBioNET 可以定位为“提供逐条文本支持、粒子归因层级及更广的方向标签”。PIDE 则提供实测的细胞生存数据。 [dbCRAF](https://academic.oup.com/narcancer/article/6/1/zcae008/7613860) · [dbCRSR](https://academic.oup.com/database/article/doi/10.1093/database/bay049/5025485) · [PIDE](https://doi.org/10.1093/jrr/rrab034)

## 每一节怎么写

- **Abstract 和 Background & Summary**。先讲一行是什么，再讲收录的语境和用途。写 15,720 条注释、178 个 Factor 标签、7,778 个不同来源标题。将 40,673 放在 Methods，定义为历史整合工作表的行数。
- **Methods**。按生产顺序写“检索与导出 → 去重与批次合并 → 字典与方向匹配 → 证据分级和记录合并 → 粒子归因与毒性标注 → 主表与派生文件”。每步交代输入、规则、输出及例外。质子流程和 13 个 Zotero 批次各自对应实际脚本。
- **Data Records**。先定义行粒度，再用表格交代 30 列和数据包目录。分别写清共现网络、剂量标记和趋势的计数单位。
- **Technical Validation**。先写可重跑的结构、来源关联和重建检查，再写独立的原文核对。报告一致、含混与错误。当前英文稿有三项定向原文核对实例，涉及粒子与药物靶点、剂量语义，以及分割方案与质子照射臂错配。
- **Usage Notes**。说明如何处理同文多行、复合方向、文本证据等级和粒子不明。把干预极性、器官受量和正式证据评级写清。可把链接预测 AUROC、光子与粒子方向翻转以及因子排序放进提出这些研究问题的文章。

## 投稿前需要补齐的内容

### 1. 还原检索到主表的版本链

四个通用 NBIB 文件和两个质子 NBIB 文件按 PMID 去重后分别有 37,473 和 5,626 个 ID，两流相交 347 个，合计 42,752 个。历史 MASTER v2 的 paper-level 表有 40,673 行、40,651 个不同标题。当前 7,778 个来源标题均能在历史表找到。两套数字对应不同阶段。已从项目流程幻灯片找回通用放疗检索式和四个日期分段，以及两套质子检索式，整理成 [PubMed 检索方案](</Users/taozy/Nutstore Files/project/RadBioNET/Scientific_Data_submission/RadBioNET_PubMed_search_protocol.txt>)。幻灯片没有留下实际执行时间、PubMed Search Details 和两套质子式分别对应哪个导出文件的记录。旧附录只写 2020–2026 年，与四个通用导出分段不一致，应以历史执行日志核对。网站曾提及 Web of Science 和 Cochrane，本地可核证的原始导出来自 PubMed。也请核实 Zotero 提示的撤稿文献如何处理，以及其他文献库是否贡献本次发布包。 [项目流程幻灯片](</Users/taozy/Nutstore Files/project/2025/放疗数据库/数据库开发流程.pptx>) · [历史检索附录](</Users/taozy/Nutstore Files/project/2025/放疗数据库/红皮杂志投稿材料准备/IJROBP_submission_0614/IJROBP/supplementary Appendix A.docx>)

13 个 Zotero 批次的四类工作表已全部复跑核对，共 52 张。通用输入按批次将规范化标题保留首行，再按规范化 DOI 保留首行；历史输出对空 DOI 也只保留每批一行，这与归档脚本中追加所有空 DOI 行的写法不同。质子流程六张工作表亦逐值吻合。MASTER 主表合并时，41,567 行文献输入按 DOI 优先、标题兜底去重为 40,673 个文献键。判定表回连少用 Factor type，形成 98 行额外匹配。应把已恢复的上游脚本、字典和输入处理记录一并随稿归档，并补上粒子归因可执行规则、毒性端点赋值规则与 140 处特定粒子修改依据。当前 PMID 全空，17 行 DOI 缺失。本次已在保留的 NBIB 中为所有 7,777 个非空 DOI 和七个无 DOI 的规范化标题分别找到唯一 PMID，但尚未改动主表。个别 DOI 含分号，勿按多标签拆开。

### 2. 对当前版本做独立原文审计

锁定版本后分层抽样，由两位审阅者独立核对，经第三人或共识会议裁决。覆盖 Strong/Weak、不同粒子归因层级、常见方向、稀有粒子、复合方向和有剂量的记录。可以先按约 200–300 条规划工作量，再根据希望达到的分层精度调整。记录随机种子、每层总体与样本量、原文位置、两人初判、裁决、修改前后的值和理由。分别报告字段正确率、分母、95% 置信区间和审阅者一致性。过抽样时报告各层结果，计算总体比例时按抽样设计加权。

逐条判断因素身份与角色是否正确，方向是否由结果支持，癌种与模型是否属于同一语境，粒子是否可归因，剂量是否属于目标组织与实验臂。将背景、方法、原文不可得和确实错误分别记录。旧质子 Methods 提到 25 Strong 加 25 Weak 的试核，旧投稿稿另提到 25 条 Strong 双人复核。先取得可追溯的样本和结果，再决定能否用于当前版。若要估计召回率，另抽候选或未入库文献做完整人工标注。

### 3. 修订影响再利用的派生文件

- **剂量**。保留原字符串和来源位置，新增剂量角色、单位、总剂量、单次剂量、分次数、是否按相对生物效应加权、实验臂或受量器官。当前导出有 4,133 个解析 token，其中没有 fractionated 记录。Loap 等原文中的 1.25 Gy 是平均心脏剂量的中位数，当前导出填成了单次剂量和总剂量。更新解析器并用已知答案的样例校验，或把现有数值派生表限定为浏览用途。 [Loap 等原文](https://pubmed.ncbi.nlm.nih.gov/40353857/)
- **方向和证据**。修正 1 条方向计数不符的记录。437 行含 Likely artifact，公布保留规则和可用的筛选条件。人工复核时补记抑制、过表达、观察或药物靶点等因素角色。
- **网络和图谱**。C 排序环境重建时，派生 CSV/JSON 与仓库版本一致。另一排序环境下，333 条边的 strong_both 改变。统一无向边顺序和连接键，更新实际五种关系的图谱 schema，确认边际计数是否应改成每文献每因素一次。趋势表改用表示注释行的列名。
- **图表**。建议正文放一张流程图和一个简短覆盖概览。流程图从两个输入流画起，标注不同 PMID 数、历史工作表行数和当前注释行数。生产日志核对后再把阶段差额写成明确的筛选步骤。用独立的验证表呈现分母和误差。

### 4. 冻结可匿名下载的版本

本地 V1.0 包已有 CSV、XLSX、RDS、字典和校验清单。工作簿与仓库版本的 SHA-256 一致。旧稿中的 Figshare 保留 DOI 为 10.6084/m9.figshare.33032213。本次公共 DOI 未解析，既有审稿入口返回 403。请在 Figshare 账号中确认可用入口，并从未登录会话测试能否下载正确版本。旧包 README 写明没有分发支持文本，但 CSV 的 15,720 行都含 Supporting sentence。逐项确认摘录的发布权限和最终许可，必要时用 DOI、文本位置和结构化标签保留溯源。改完后同步全部数据格式、字典、README、校验清单和正文统计。期刊要求首轮可匿名下载，从第二轮起需在正式仓储公开。 [旧 V1.0 包说明](</Users/taozy/Nutstore Files/project/2025/放疗数据库/scientific data投稿/0720/RadBioNET_V1.0_data_package/README.md>) · [期刊数据政策](https://www.nature.com/sdata/policies/data-policies) · [投稿指南](https://www.nature.com/sdata/publish/submission-guidelines)

## 本次稿件的基准与复跑方式

英文稿基于仓库提交 69255784cfad6fb4bd0101b9aa848a22db09d59e，沿用 7 月稿的署名和投稿材料中的声明，仍需作者确认。英文方括号仅保留给尚未取得的历史执行日志、粒子和毒性赋值实现、独立原文审计、仓储入口和作者声明。若相关研究稿已经公开，在 Background & Summary 引用，并交代这次新增的数据、说明或验证材料。 [7 月英文稿](</Users/taozy/Nutstore Files/project/2025/放疗数据库/scientific data投稿/0721/manuscript_Data_Descriptor_revised.docx>) · [期刊既往发表政策](https://www.nature.com/sdata/policies/editorial-and-publishing-policies)

从 RadBioNET 根目录执行下面命令。核对脚本在临时目录重建派生文件。附带上游路径后，也会核对原始导出、历史工作表和历史判定阈值。

```sh
Rscript --vanilla Scientific_Data_submission/audit_snapshot.R '../2025/放疗数据库'
```
