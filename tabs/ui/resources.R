resources_tab <- tabPanel(
  title = "Resource Hub",
  value = "resources",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 24px 35px; margin-top: 6px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h2(style = "margin: 0 0 10px 0; font-weight: 700; color: #1a5276;", icon("book"), " Data Resources"),
        p(style = "margin: 0 0 10px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          "This page collects the main ", strong("publicly available or application-based"), " data resources across radiotherapy, radiation physics, and radiobiology, so that researchers can find them in one place. All resources are maintained by third parties and are ", strong("not RadBioNet's own data"), "."),
        p(style = "margin: 0; font-size: 13px; color: #888; font-style: italic;",
          icon("calendar-check"), " Directory last verified: June 2026. Access policies, size, and licensing of each resource may change at any time — always confirm on the resource's own website before use.")
      )
    )
  ),
  fluidRow(
    column(width = 10, offset = 1,
      div(class = "section-title", "1. Data Commons"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://datacommons.cancer.gov", target = "_blank", "NCI Cancer Research Data Commons (CRDC)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— datacommons.cancer.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "The US National Cancer Institute's (NCI) cancer-research data cloud, which connects imaging, genomic, proteomic, and other data nodes under one roof and provides a cloud-based analysis environment. It includes the Imaging Data Commons (IDC), Genomic Data Commons (GDC), Proteomic Data Commons (PDC), and others."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Mostly open access; some controlled data requires dbGaP authorization.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://portal.imaging.datacommons.cancer.gov", target = "_blank", "Imaging Data Commons (IDC)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— portal.imaging.datacommons.cancer.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "The imaging node of CRDC, which integrates and cloud-hosts a large share of TCIA's imaging (including DICOM-RT) for direct browser- and cloud-based viewing, querying, and analysis."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free and public, no application required; cloud compute supported.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://seer.cancer.gov", target = "_blank", "SEER (Surveillance, Epidemiology, and End Results)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— seer.cancer.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "NCI's population-based cancer registry database covering incidence, mortality, and long-term survival/follow-up — a key source for radiotherapy outcomes and epidemiology research."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("database"), " Clinical and survival data on millions of cases across multiple US registries. ",
          icon("unlock"), " Summary statistics free and public; case-level research requires signed data-use agreement."
        )
      ),
      br(),
      div(class = "section-title", "2. Imaging & DICOM-RT Datasets"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.cancerimagingarchive.net", target = "_blank", "The Cancer Imaging Archive (TCIA)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— cancerimagingarchive.net")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "The central public oncology imaging archive, organized into 'collections.' Many collections include full DICOM-RT files — structure sets (RTSTRUCT), dose (RTDOSE), and plans (RTPLAN) — and are often paired with clinical outcomes, genomics, and expert annotations."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("database"), " Hundreds of collections spanning many tumor types and modalities (CT/MRI/PET, etc.). ",
          icon("unlock"), " Free public download, most under CC BY licensing."
        )
      ),
      div(class = "chart-card", style = "padding: 15px 20px; background: #fafbfc;",
        p(style = "font-size: 12px; color: #666; margin: 0 0 4px 0; font-style: italic;",
          "Selected radiotherapy-relevant TCIA collections:"),
        p(style = "font-size: 12px; color: #555; margin: 2px 0; line-height: 1.7;",
          strong("NSCLC-Radiomics"), " — NSCLC CT with GTV and OAR contours; a classic radiomics dataset. ",
          strong("Head-Neck / HNSCC series"), " — head-and-neck cases with planning CT, structure sets, and dose. ",
          strong("GLIS-RT"), " — glioma segmentation for radiotherapy. ",
          strong("Pancreatic-CT-CBCT-SEG"), " — breath-hold CT and CBCT with expert OAR segmentations. ",
          strong("Brain-TR-GammaKnife"), " — Gamma Knife brain-metastasis MRI with paired DICOM-RT."
        )
      ),
      br(),
      div(class = "section-title", "3. Planning & Dosimetry Datasets"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.aapm.org/GrandChallenge/", target = "_blank", "OpenKBP dataset"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— AAPM Grand Challenge")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "Public data from the AAPM 2020 knowledge-based planning challenge: ~340 head-and-neck IMRT plans (CT, structures, dose). One of the most widely used benchmarks in dose prediction."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free via the challenge's GitHub repository.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.aapm.org/GrandChallenge/GDP-HMM/", target = "_blank", "GDP-HMM / HMM-RT dataset"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— AAPM 2025 Challenge")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "The AAPM 2025 'Generalizable Dose Prediction for Heterogeneous Multi-cohort and Multi-site Radiotherapy Planning' challenge dataset — over ten times larger than existing public plan datasets, with a DICOM version also provided."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free via the challenge platform and GitHub (registration).")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.aapm.org/GrandChallenge/", target = "_blank", "AAPM Grand Challenges hub"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— aapm.org/GrandChallenge")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "Entry point for AAPM's medical-physics challenges over the years, including RT-MAC (head-and-neck MR auto-segmentation), OpenKBP, lung target tracking (MATCH), and other radiotherapy tasks and datasets."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Most challenge data is free; some requires registration or accepting terms.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://grand-challenge.org", target = "_blank", "Grand Challenge"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— grand-challenge.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A general platform for medical-imaging AI challenges and datasets, covering many segmentation, detection, and registration tasks, some radiotherapy-related."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free registration; dataset access varies by challenge.")
      ),
      br(),
      div(class = "section-title", "4. Clinical Trial & Outcomes Data"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.projectdatasphere.org", target = "_blank", "Project Data Sphere"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— projectdatasphere.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A free oncology clinical-trial 'library-laboratory' that shares de-identified patient-level data from Phase II/III trials, with free analysis tools provided."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("database"), " Hundreds of studies and over 100,000 patient lives. ",
          icon("unlock"), " Free after registration; no research proposal required."
        )
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://nctn-data-archive.nci.nih.gov", target = "_blank", "NCI NCTN/NCORP Data Archive"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— nctn-data-archive.nci.nih.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A controlled-access repository run by NCI in partnership with Project Data Sphere, centrally storing and sharing patient-level datasets generated by the US National Clinical Trials Network (NCTN)."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("lock"), " Controlled access; requires a data request and approval.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://clinicaltrials.gov", target = "_blank", "ClinicalTrials.gov"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— clinicaltrials.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "The largest clinical-trials registry, where you can search protocols, eligibility criteria, sample sizes, and some results. Many radiotherapy trial protocols and plan-QA details can be found here."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free and public, no registration.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://vivli.org", target = "_blank", "Vivli / CSDR and other industry data-sharing platforms"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— vivli.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "Cross-organization platforms for sharing clinical-trial data (including CSDR, YODA, etc.), covering controlled-access patient-level data from many industry-sponsored trials."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("lock"), " Controlled access; typically requires a research proposal and approval.")
      ),
      br(),
      div(class = "section-title", "5. Dose Constraints & NTCP"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          "QUANTEC",
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— Int. J. Radiat. Oncol. Biol. Phys. (2010 special issue)")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "'Quantitative Analyses of Normal Tissue Effects in the Clinic' — the foundational compilation of organ dose–volume limits for conventional fractionation, still a primary reference for clinical planning.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          "HyTEC",
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— Int. J. Radiat. Oncol. Biol. Phys. (special issue)")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "'Hypofractionated Treatment Effects in the Clinic' — dose–response and limits for hypofractionated regimens such as SBRT/SRS, and also covers tumor control probability (TCP) for several sites.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          "PENTEC",
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— Int. J. Radiat. Oncol. Biol. Phys. / Clinical Oncology")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "'Pediatric Normal Tissue Effects in the Clinic' — compiled by 150+ experts across 18 organ-specific working groups, focused on dose–volume–risk relationships in pediatric radiotherapy.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          "Emami 1991 tolerance tables",
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— historic classic")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.6;",
          "The historic classic tables of organ tolerance doses, cited thousands of times and the origin of the work above. All of the above are journal publications (some open access, some by subscription); the constraint tables are widely reproduced in reviews and treatment-planning systems.")
      ),
      br(),
      div(class = "section-title", "6. Contouring Atlases & Standards"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://econtour.org", target = "_blank", "eContour"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— econtour.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A free, online, case-based interactive contouring atlas with 3D scrollable imaging and contours, compiling consensus recommendations by disease site and OAR, updated regularly."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free, requires a (free) account; web-based only, no downloads.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.nrgoncology.org/about-us/center-for-innovation-in-radiation-oncology", target = "_blank", "NRG Oncology / RTOG contouring atlases"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— nrgoncology.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A series of consensus contouring atlases from NRG (formerly RTOG) — e.g., male/female pelvic normal tissue, upper-abdominal organs, hippocampus — used to standardize contouring for clinical trials."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free on the official site; some items require a free login.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          "Head-and-neck OAR international consensus (Brouwer et al., 2015)",
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— Radiotherapy and Oncology")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.6;",
          "A multi-institution (DAHANCA/EORTC/GORTEC/NRG, etc.) consensus for head-and-neck OAR delineation, adopted as the standard by many auto-segmentation datasets and trials.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.aapm.org/pubs/reports/", target = "_blank", "AAPM TG-263 nomenclature standard"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— aapm.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.6;",
          "The standardized nomenclature for radiotherapy structures and dose — an important foundation for cross-institution data integration and interoperability.")
      ),
      br(),
      div(class = "section-title", "7. Radiobiology & Radiogenomics"),
      hr(class = "section-divider"),
      div(style = "background: #fef9e7; border-radius: 8px; padding: 10px 18px; margin-bottom: 12px; border-left: 4px solid #fdc23a;",
        p(style = "font-size: 12px; color: #856404; margin: 0;",
          icon("lightbulb"), " This category aligns most closely with RadBioNet's radiobiology focus.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://epi.grants.cancer.gov/radiogenomics/", target = "_blank", "Radiogenomics Consortium (RGC)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— epi.grants.cancer.gov/radiogenomics")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "An international collaboration founded in 2009 and supported by NCI, pooling multi-center cohorts to study genetic susceptibility (SNPs, etc.) to radiotherapy toxicity, with extensive work across prostate, breast, lung, head-and-neck, and other cancers."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("lock"), " Through collaborative research; data is mostly shared via member cohorts and partnerships.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.requite.eu", target = "_blank", "REQUITE"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— requite.eu")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "An RGC-led prospective project that collected standardized clinical, biological, and genotype data for ~5,000–5,300 lung/prostate/breast cancer patients, with a centralized database and linked biobank, used to validate predictive models and biomarkers for radiotherapy toxicity."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("lock"), " Centralized database and biobank, available via application/collaboration.")
      ),
      br(),
      div(class = "section-title", "8. Molecular & Omics Data"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://portal.gdc.cancer.gov", target = "_blank", "TCGA / GDC (Genomic Data Commons)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— portal.gdc.cancer.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "Multi-omics characterization (genomic, epigenomic, transcriptomic, proteomic) of 20,000+ samples across 33 tumor types, with clinical and survival data; accessed through the GDC Data Portal with built-in analysis tools."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("database"), " 2.5+ PB of multi-omics data. ",
          icon("unlock"), " Open-access data free to download; controlled data requires dbGaP authorization."
        )
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.cbioportal.org", target = "_blank", "cBioPortal for Cancer Genomics"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— cbioportal.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A portal for visualizing and exploring cancer genomics data (including TCGA and many study cohorts), well suited to quick queries of gene alterations and clinical associations."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free, web-based, no registration.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://pdc.cancer.gov", target = "_blank", "Proteomic Data Commons / CPTAC"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— pdc.cancer.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.6;",
          "The proteomic node of CRDC, hosting CPTAC and other clinical proteogenomic data.")
      ),
      br(),
      div(class = "section-title", "9. Physics Reference Data"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.nist.gov/pml/xcom-photon-cross-sections-database", target = "_blank", "NIST XCOM / mass attenuation coefficients"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— nist.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A database of photon cross sections and mass attenuation coefficients for elements, compounds, and mixtures."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free online query.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.nist.gov/pml/stopping-power-range-tables-electrons-protons-and-helium-ions", target = "_blank", "NIST ESTAR / PSTAR / ASTAR"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— nist.gov")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "Stopping-power and range tables for electrons, protons, and helium ions — a common reference for particle therapy and dosimetry."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Free online query.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.icru.org", target = "_blank", "ICRU / ICRP reports"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— icru.org / icrp.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.6;",
          "International authoritative standards for radiation quantities, dosimetry, and protection. ICRP offers many free PDFs; ICRU reports are generally paid publications.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.nndc.bnl.gov", target = "_blank", "Nuclear data libraries (ENDF/JANIS, etc.)"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— nndc.bnl.gov / oecd-nea.org/janisweb")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.6;",
          "Evaluated nuclear data libraries used for neutron and other particle transport in advanced Monte Carlo modeling.")
      ),
      br(),
      div(class = "section-title", "10. Open-Source Software Tools"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://www.slicer.org", target = "_blank", "3D Slicer"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "+"),
          tags$a(href = "https://slicerrt.github.io", target = "_blank", "SlicerRT", style = "font-size: 14px;")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A free, open-source platform for medical-image visualization and analysis; the SlicerRT extension adds nearly 20 radiotherapy modules (DICOM-RT read/write, deformable registration, dose comparison, etc.). Cross-platform (Windows/Mac/Linux)."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source (BSD).")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://e0404.github.io/matRad", target = "_blank", "matRad"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— DKFZ")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "An open-source multimodality dose-calculation and inverse-planning toolkit supporting photons, protons, and carbon ions, with bundled CORT example patient data. Runs in MATLAB or free under Octave."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source (GPL v3). Actively developed.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://cerr.github.io/CERR/", target = "_blank", "CERR"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— Computational Environment for Radiotherapy Research")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A classic open-source radiotherapy research platform for importing, analyzing, and comparing plans, supporting reproducible algorithm development. Written in MATLAB."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://opentps.org", target = "_blank", "OpenTPS"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— opentps.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A newer open-source treatment planning system, written in Python, focused on proton therapy and research use."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://plastimatch.org", target = "_blank", "Plastimatch"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— plastimatch.org")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "An open-source toolkit for image registration and DICOM-RT conversion, integrated by SlicerRT and others."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source (BSD).")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://pyradiomics.readthedocs.io", target = "_blank", "PyRadiomics"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— pyradiomics.readthedocs.io")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "The open-source standard library for radiomics feature extraction (IBSI-aligned), extracting ~1,500 features from images and masks, with a 3D Slicer front-end extension."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source (3-clause BSD).")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://github.com/dicompyler/dicompyler-core", target = "_blank", "dicompyler-core"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— github.com/dicompyler")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "A lightweight Python library for parsing DICOM-RT and independently computing DVHs and dose data — well suited to scripted analysis."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          tags$a(href = "https://github.com/cutright/DVH-Analytics", target = "_blank", "DVH Analytics"),
          tags$span(style = "font-size: 12px; font-weight: 400; color: #888; margin-left: 8px;", "— github.com/cutright")
        ),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 6px 0; line-height: 1.6;",
          "An open-source application that imports DICOM-RT plan data into a SQL database, providing plan comparison, benchmarking, outcome prediction, and a web-based interface."),
        p(style = "font-size: 12px; color: #888; margin: 0;",
          icon("unlock"), " Open-source.")
      ),
      div(class = "chart-card", style = "padding: 15px 20px;",
        tags$h4(style = "font-weight: 700; color: #098ebb; margin: 0 0 2px 0;",
          "Monte Carlo simulation tools"),
        p(style = "font-size: 13px; color: #555; margin: 4px 0 0 0; line-height: 1.7;",
          strong(tags$a(href = "https://geant4.web.cern.ch", target = "_blank", "Geant4")), " — CERN's general-purpose particle-transport toolkit; open-source and free.", tags$br(),
          strong(tags$a(href = "https://www.topasmc.org", target = "_blank", "TOPAS")), " — A Geant4-based wrapper aimed at proton/particle therapy; free for research use (registration required).", tags$br(),
          strong(tags$a(href = "https://opengate.readthedocs.io", target = "_blank", "GATE")), " — Geant4-based, for imaging and dosimetry simulation; open-source.", tags$br(),
          strong(tags$a(href = "https://github.com/nrc-cnrc/EGSnrc", target = "_blank", "EGSnrc")), " — The Canadian NRC's electron–photon transport system (including BEAMnrc linac modeling); open-source and free.", tags$br(),
          strong("MCNP / PENELOPE"), " — Controlled distribution; license must be requested via RSICC / NEA."
        )
      ),
      br(),
      div(style = "background: #f8f9fa; border-radius: 10px; padding: 16px 20px; margin-top: 10px; border-left: 4px solid #098ebb;",
        h5(style = "font-weight: 700; color: #333; margin: 0 0 8px 0;", icon("clipboard-list"), " Maintenance notes"),
        p(style = "font-size: 12px; color: #666; margin: 2px 0; line-height: 1.6;",
          "Every entry records its access method and whether an application is required. Controlled-access resources (NCTN, Vivli, REQUITE, GDC controlled tier, etc.) change their application requirements and timelines fairly often — always confirm on the resource's own website before use.")
      ),
      br()
    )
  )
)
