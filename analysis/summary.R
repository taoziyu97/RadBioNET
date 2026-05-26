library(tidyverse)
summary <- readxl::read_xlsx("analysis/summary.xlsx") %>% 
  dplyr::mutate(
    `cancer type` = tolower(`cancer type`)
  )
sum_cancer <- dplyr::select(
  summary,
  `cancer type`, Title
) %>% 
  dplyr::distinct(
    Title, .keep_all = TRUE
  ) %>% 
  dplyr:::group_by(
    `cancer type`
  ) %>% 
  summarise(
    n = n()
  ) %>% 
  as.data.frame()
sum_cancer <- table(summary$`cancer type`) %>% 
  as.data.frame()
colnames(sum_cancer) <- c("cancer type", "number")
# sum_cancer <- sum_cancer %>%
#   mutate(`cancer type` = factor(`cancer type`, 
#                                 levels = sum_cancer$`cancer type`[order(number)])) 
sum_cancer <- sum_cancer %>%
  arrange(desc(number)) %>% 
  mutate(`cancer type` = factor(`cancer type`, levels = `cancer type`))   # 这里 levels 按当前顺序



library(ggplot2)
# 示例数据
# df <- data.frame(
#   group = c("A", "B", "C", "D"),
#   value = c(12, 25, 18, 30),
#   type  = c("X", "Y", "X", "Y")  # 用于图例
# )

# 基本条形图
p <- ggplot(
  sum_cancer, 
  aes(
    x = `cancer type`, 
    y = number
  )) +
  geom_bar(stat = "identity", position = position_dodge(), fill = "#6394EB") +  # 条形图
  # geom_text(aes(label = number), 
  #           vjust = -0.3,              # 文字位置（-0.3表示在柱子上方）
  #           position = position_dodge(0.9), 
  #           size = 3.5) +              # 字体大小
  theme_classic() +
  labs(title = "", 
       x = "", 
       y = "Number", 
       fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1) # 横坐标文字竖着显示
  )

print(p)

# 去除正常样本的癌症类型
sum_cancer_drop_normal <- sum_cancer %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
      "kidney cancer", 
      "renal cell carcinoma"
    ) ~ "kidney cancer", 
    .default = `cancer type`
    )
  ) %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
        "nasopharyngeal carcinoma", 
        "nasopharyngeal cancer"
      ) ~ "nasopharyngeal cancer", 
      .default = `cancer type`
    )
  ) %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
        "orpharyngeal squamous cell carcinoma", 
        "oropharyngeal squamous cell carcinoma"
      ) ~ "oropharyngeal squamous cell carcinoma", 
      .default = `cancer type`
    )
  ) %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
        "esophageal squamous cell carcinoma", 
        "esophageal cancer"
      ) ~ "esophageal cancer",
      .default = `cancer type`
    )
  ) %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
        "hepatocellular carcinoma", 
        "liver cancer"
      ) ~ "liver cancer",
      .default = `cancer type`
    )
  ) %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
        "oropharyngeal squamous cell carcinoma", 
        "oropharyngeal cancer"
      ) ~ "oropharyngeal cancer",
      .default = `cancer type`
    )
  ) %>% 
  dplyr::mutate(
    `cancer type` = case_when(
      `cancer type` %in% c(
        "head and neck cancer",
        # "oral squamous cell carcinoma",
        "hypopharyngeal cancer",
        "oropharyngeal cancer"
        # "nasopharyngeal cancer"
      ) ~ "head and neck cancer",
      .default = `cancer type`
    )
  ) %>%
  group_by(`cancer type`) %>%
  summarise(number = sum(number, na.rm = TRUE)) %>%
  ungroup() %>% 
  dplyr::arrange((number)) %>% 
  dplyr::filter(
   !(`cancer type` %in% c(
     "cancer cell",
     "xeroderma pigmentosum",
     "health tissue",
     "bone mesenchymal"
     ))
  )

p <- ggplot(
  sum_cancer_drop_normal, 
  aes(
    x = number, 
    y = reorder(`cancer type`, number)  # 按数量重新排序癌症类型
  )) +
  geom_bar(stat = "identity", position = position_dodge(), fill = "#6394EB") +  # 条形图
  # geom_text(aes(label = number), 
  #           vjust = -0.3,              # 文字位置（-0.3表示在柱子上方）
  #           position = position_dodge(0.9), 
  #           size = 3.5) +              # 字体大小
  theme_classic() +
  labs(title = "", 
       x = "Number", 
       y = "", 
       fill = "") 
  # theme(
  #   axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1) # 横坐标文字竖着显示
  # )

print(p)

p2 <- ggplot(
  sum_cancer_drop_normal, 
  aes(
    x = reorder(`cancer type`, number, decreasing = T), 
    y = number # 按数量重新排序癌症类型
  )) +
  geom_bar(stat = "identity", position = position_dodge(), fill = "#6394EB") +  # 条形图
  # geom_text(aes(label = number), 
  #           vjust = -0.3,              # 文字位置（-0.3表示在柱子上方）
  #           position = position_dodge(0.9), 
  #           size = 3.5) +              # 字体大小
  theme_classic() +
  labs(title = "", 
       x = "", 
       y = "Number", 
       fill = "") +
  theme(
  axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1) # 横坐标文字竖着显示
)
p2

ggplot2::ggsave("pic/cancer_number.pdf", plot = p, width = 5, height = 5)



# 加速器 ---------------------------------------------------------------------
library(tidyverse)
summary <- readxl::read_xlsx("analysis/summary.xlsx") %>% 
  dplyr::mutate(
    `cancer type` = tolower(`cancer type`)
  ) %>% 
  dplyr::filter(
    `DOI...15` != "10.1007/s12032-025-02717-1"
  )
sum_mechine <- table(summary$`radiation mechine2`) %>% 
  as.data.frame()
colnames(sum_mechine) <- c("radiation mechine", "number")
sum_mechine <- sum_mechine %>%
  arrange(desc(number)) %>% 
  dplyr::filter(
    `radiation mechine` != "X-ray machine (6-MeV X-ray beam generated by a clinical  linear accelerator, Siemens, Primus, Germany)"
  ) %>% 
  mutate(`radiation mechine` = factor(`radiation mechine`, levels = `radiation mechine`))   # 这里 levels 按当前顺序

# 只取前 20
mechine_top30 <- sum_mechine %>% 
  dplyr::filter(
    `radiation mechine` != "Unknown"
  ) %>% 
  slice(1:30)

p <- ggplot(
  mechine_top30, 
  aes(
    x = number, 
    y = reorder(`radiation mechine`, number) # 按数量重新排序癌症类型
  )
) +
  geom_bar(stat = "identity", fill = "#E4D368") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p)

ggplot2::ggsave("pic/mechine_number.pdf", plot = p, width = 7, height = 5)


xray_devices <- c(
  "6 MV X-ray irradiation",
  "RS-2000 X-ray irradiator",
  "X-Rad 320 irradiator", 
  "CellRad, Precision X-Ray, Madison, CT, USA",
  "X-ray irradiation device (X-RAD225, PXi, USA)",
  "RS-2000-PRO-225 Biological Irradiator",
  "X-ray irradiator (Varian23EX; VARIAN, USA)",
  "Xstrahl CIX3 irradiator",
  "Gulmay RS225 irradiation machine",
  "X-ray linear accelerator (Clinac 2100EX)",
  "200 kVp X-rays (Pantak 320S)",
  "Faxitron RX-650 irradiation device (Tucson)",
  "IC-320 orthovoltage irradiator",
  "linac X-ray radiation",
  "ray irradiation equipment (MBR1520R-3; Hitachi, Tokyo, Japan)",
  "SmART Irradiator of Precision X‐Ray Inc",
  "Xstrahl 320 Kv generator",
  "13-mA x-ray with a single dose of 12.5 or 15 Gy",
  "Faxitron X-ray machine",
  "CIX3 cabinet irradiator [Xstrahl Inc. Suwanee GA]",
  "Philips RT250 X-ray generator",
  "photon beams (Varian unique linear accelerator, USA)",
  "Rad Source 2000 X-ray irradiator 187",
  "Radgil2, an X-Ray irradiator",
  "RS320 X-Ray machine by XStrahl Ltd.",
  "X-ray generator (MBR-1520R-3; Hitachi Medical Co. Ltd.)",
  "X-ray instruments, Chinese Academy of Sciences",
  "X-ray irradiator (Elekta, Sweden);RS-200 Pro Biological Irradiator",
  "X-ray linear accelerator (PRIMUS, D. E.; Siemens, Malvern, PA, USA).",
  "X-ray linear accelerator (Varian Trilogy, USA)",
  "X-ray machine (6-MeV X-ray beam, Siemens, Primus, Germany)",
  "X-ray machine M-150WE (SOFTEX, Tokyo, Japan)",
  "X-ray unit (MBR-1505R; Hitachi, Hitachi, Japan)",
  
  "X-ray linear accelerator (PRIMUS, D. \nE.; Siemens, Malvern, PA, USA).", #
  "X-ray machine (6-MeV X-ray beam, Siemens, Primus, Germany)", # 这个始终无法合并
  "X-ray unit (MBR-1505R; Hitachi, Hitachi,\nJapan)"
)
linac_devices <- c(
  "a linear accelerator (2008 Synergy s/n 151765; Elekta)", #
  "linear accelerator (21EX, Varian, Palo Alto, CA,\nUSA)", #
  "linear accelerator (Varian 2300EX, dose rate of 2 Gy/min; Varian, USA)", #
  "Varian linear accelerator, USA, at a dose rate of 300 MU/min", #
  
  "9-MeV electron linear accelerator",
  "X-ray linear accelerator (Clinac 2100EX)",
  "linear accelerator ((MHCL-15S, Mitsubishi Electric Co., Tokyo, Japan)",
  "linear accelerator at Oslo University Hospital", 
  "linear accelerator PRIMUS-H (Siemens)",
  "linear accelerator (2008 Synergy s/n 151765; Elekta)",
  "e linear accelerator machine (Artiste®, Siemens Medical Solutions USA, Inc., Malvern, PA)",
  "linear accelerator (21EX, Varian, Palo Alto, CA, USA)",
  "linear accelerator (LINAC SL25 Philips, DA Best, Netherlands)",
  "linear accelerator (Varian 2300EX, dose rate of 2 Gy/min; Varian, USA)",
  "linear accelerator (Varian Clinic 21ES, Palo Alto, CA, USA)",
  "Linear Accelerator (Versa HD, Elekta)",
  "medical linear accelerator (Precise Accelerator, Elekta, Sweden)",
  "TrueBeam linear accelerator",
  "Varian 21EX linear accelerator (Palo Alto, CA)",
  "Varian 23EX and 120-leaf MLC 600C/D linear accelerators",
  "Varian Clinac 21Ex at 6 Gy/min",
  "6 MeV beams of an Elekta synergy linac",
  "arian 21EX Linear Accelerator",  # 注意：这是"Varian"的拼写错误
  "CLINAC 6EX"
)
gamma_sources <- c(
  "Gammacell 40 Exactor Irradiator",
  "Cs-137 radiator", 
  "cobalt 60 source",
  "gamma Irradiator-2000 (BRIT, Mumbai, India)",
  "Iodine-125 seed"  # 碘125种子源
)
heavy_ion_devices <- c(
  "The MedAustron particle therapy accelerator facility",
  "Osaka HIMAK",
  "Lanzhou Heavy Ion Research Facility (HIRFL)",
  "C-ions irradiation; X-Rad 225 system",
  "Heavy Ion Medical Accelerator in Chiba (HIMAC)",
  "HVEE Singletron accelerator"
)
proton_therapy <- c(
  "ProBeam system (Varian Medical Systems)",
  "PROBEAT Proton Beam Therapy System",
  
  "PROBEAT Proton Beam\nTherapy System"
)
research_platforms <- c(
  "Johns Hopkins University Small Animal Radiation Research Platform",
  "Small Animal Radiation Research Platform (SARRP)",
  "experimental hall of the UPTD",
  "ceramic infrared irradiator (model no. S-O.T.M 9H, Saeik Medical Co., Ltd., Gyeonggi-do, Republic of Korea)"
)
planning_systems <- c(
  "RayStation (RaySearch Laboratories, Stockholm, Sweden) and VQA Plan (Hitachi Ltd., Tokyo, Japan)"
)
clinical_treatments <- c(
  "long course radiation therapy (a total dose of 50 Gy in 25 fractions), and combined with oral capecitabine (825 mg/m2 twice a day) on radiotherapy days only"
)
medical_facilities <- c(
  "Nemazee hospital"
)
mechine_relist <- sum_mechine %>% 
  dplyr::mutate(
    `radiation mechine` = case_when(
      `radiation mechine` %in% xray_devices ~ "xray devices",
      `radiation mechine` %in% linac_devices ~ "linac devices",
      `radiation mechine` %in% gamma_sources ~ "gamma sources",
      `radiation mechine` %in% heavy_ion_devices ~ "heavy ion devices",
      `radiation mechine` %in% proton_therapy ~ "proton therapy",
      `radiation mechine` %in% research_platforms ~ "research platforms",
      `radiation mechine` %in% planning_systems ~ "planning systems",
      `radiation mechine` %in% clinical_treatments ~ "clinical treatments",
      `radiation mechine` %in% medical_facilities ~ "medical facilities",
      .default = `radiation mechine`
    )
  ) %>% 
  dplyr:::group_by(
    `radiation mechine`
  ) %>% 
  summarise(
    number = sum(number)
  ) %>% 
  as.data.frame() 
# sum_mechine <- table(mechine_relist$`radiation mechine`) %>% 
#   as.data.frame()
# colnames(sum_cancer) <- c("cancer type", "number")


p <- ggplot(
  mechine_relist, 
  aes(
    x = number, 
    y = reorder(`radiation mechine`, number) # 按数量重新排序癌症类型
    )
) +
  geom_bar(stat = "identity", fill = "#E4D368") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p)

ggplot2::ggsave("pic/mechine_classification.pdf", plot = p, width = 5, height = 5)


# 敏感/抵抗 ---------------------------------------------------------------------
library(tidyverse)
summary <- readxl::read_xlsx("analysis/summary.xlsx") %>% 
  dplyr::mutate(
    `cancer type` = tolower(`cancer type`)
  )
sum_change <- table(summary$change) %>% 
  as.data.frame()
colnames(sum_change) <- c("change", "number")
sum_change <- sum_change %>%
  arrange(desc(number)) %>% 
  mutate(change = factor(change, levels = change))   # 这里 levels 按当前顺序

# 只取前 20
change_top30 <- sum_change %>% slice(1:30)

p <- ggplot(
  change_top30, 
  aes(x = change, y = number)
) +
  geom_bar(stat = "identity", fill = "#B7C94B") +
  theme_classic() +
  labs(title = "", x = "", y = "Number", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p)

p2 <- ggplot(
  change_top30, 
  aes(x = number, y = reorder(change, number))
) +
  geom_bar(stat = "identity", fill = "#B7C94B") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p2)

# 因子 ----------------------------------------------------------------------
# 按 number 从大到小排序，并且保留排序后的 factor 顺序
sum_facor <- table(summary$factor) %>% 
  as.data.frame()
colnames(sum_facor) <- c("factor", "number")
sum_facor <- sum_facor %>%
  arrange(desc(number)) %>% 
  mutate(factor = factor(factor, levels = factor))   # 这里 levels 按当前顺序

# 只取前 20
top20 <- sum_facor %>% slice(1:30)

p <- ggplot(
  top20, 
  aes(x = factor, y = number)
) +
  geom_bar(stat = "identity", fill = "#9BC0B4") +
  theme_classic() +
  labs(title = "", x = "", y = "Number", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p)

p2 <- ggplot(
  top20, 
  aes(x = number, y = reorder(factor, number))
) +
  geom_bar(stat = "identity", fill = "#9BC0B4") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p2)
ggplot2::ggsave("pic/specific_factor_number.pdf", plot = p2, width = 7, height = 5)


# radiation ---------------------------------------------------------------
library(tidyverse)
summary <- readxl::read_xlsx("analysis/summary.xlsx") %>% 
  dplyr::mutate(
    `cancer type` = tolower(`cancer type`)
  )
sum_therapy <- table(summary$radiation) %>% 
  as.data.frame()
colnames(sum_therapy) <- c("radiation type", "number")
sum_therapy <- sum_therapy %>%
  arrange(desc(number)) %>% 
  mutate(`radiation type` = factor(`radiation type`, levels = `radiation type`))   # 这里 levels 按当前顺序

# 只取前 20
change_top30 <- sum_therapy %>% slice(1:30)

p <- ggplot(
  change_top30, 
  aes(x = `radiation type`, y = number)
) +
  geom_bar(stat = "identity", fill = "#235AEF") +
  theme_classic() +
  labs(title = "", x = "", y = "Number", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p)

p2 <- ggplot(
  change_top30, 
  aes(x = number, y = reorder(`radiation type`, number))
) +
  geom_bar(stat = "identity", fill = "#235AEF") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p2)

ggplot2::ggsave("pic/radiation_type.pdf", plot = p2, width = 5, height = 5)

# evidence ---------------------------------------------------------------
library(tidyverse)
summary <- readxl::read_xlsx("analysis/summary.xlsx") %>% 
  dplyr::mutate(
    `cancer type` = tolower(`cancer type`)
  )
sum_evidence1 <- table(summary$evidence1) %>% 
  as.data.frame()
colnames(sum_evidence1) <- c("evidence", "number")
sum_evidence1 <- sum_evidence1 %>%
  arrange(desc(number)) %>% 
  mutate(evidence = factor(evidence, levels = evidence))   # 这里 levels 按当前顺序

# 只取前 20
# change_top30 <- sum_evidence1 %>% slice(1:30)

p <- ggplot(
  sum_evidence1, 
  aes(x = evidence, y = number)
) +
  geom_bar(stat = "identity", fill = "#D4836F") +
  theme_classic() +
  labs(title = "", x = "", y = "Number", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p)

p2 <- ggplot(
  sum_evidence1, 
  aes(x = number, y = reorder(evidence, number))
) +
  geom_bar(stat = "identity", fill = "#D4836F") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p2)
ggplot2::ggsave("pic/evidence_type.pdf", plot = p2, width = 6, height = 5)

# evidence ---------------------------------------------------------------
library(tidyverse)
summary <- readxl::read_xlsx("analysis/summary2.xlsx") %>% 
  dplyr::mutate(
    `cancer type` = tolower(`cancer type`)
  )
sum_dose <- table(summary$dose) %>% 
  as.data.frame()
colnames(sum_dose) <- c("dose", "number")
sum_dose <- sum_dose %>%
  arrange(desc(number)) %>% 
  mutate(dose = factor(dose, levels = dose))   # 这里 levels 按当前顺序

# 只取前 20
dose_top20 <- sum_dose %>% slice(1:20)

p2 <- ggplot(
  dose_top20 %>% 
    dplyr::filter(dose != "Unknown"), 
  aes(x = number, y = reorder(dose, number))
) +
  geom_bar(stat = "identity", fill = "#D2658E") +
  theme_classic() +
  labs(title = "", x = "Number", y = "", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p2)
ggplot2::ggsave("pic/dose.pdf", plot = p2, width = 5, height = 5)

p2 <- ggplot(
  dose_top20 , 
  aes(x = number, y = dose)
) +
  geom_bar(stat = "identity", fill = "#D2658E") +
  theme_classic() +
  labs(title = "", x = "", y = "Number", fill = "") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

print(p2)

