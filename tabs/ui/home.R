home <- tabPanel(
  title = "Home",
  value = "home",
  hr(),
  fluidRow(
    column(width = 12,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 28px 35px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h1(style = "margin: 0 0 12px 0; font-size: 28px; font-weight: 700; color: #1a5276; font-family: Open Sans;",
          "RadBioNet"),
        p(style = "margin: 0 0 12px 0; font-size: 15px; color: #2c3e50; line-height: 1.6; font-family: Source Sans Pro;",
          HTML("<b>RadBioNet</b> (Radiation Biology Network) is a curated database and interactive platform developed by the <span style='color:#19509A;font-weight:bold'>Department of Radiation Oncology</span> at <b>Ruijin Hospital</b>, Shanghai JiaoTong University School of Medicine.")),
        p(style = "margin: 0 0 8px 0; font-size: 14px; color: #34495e; line-height: 1.6; font-family: Source Sans Pro;",
          "The platform serves as a central hub for collecting, visualizing, and exploring factors associated with radiation sensitivity and resistance in cancer. It supports the global radiation oncology research community by providing:"),
        div(style = "font-size: 14px; color: #34495e; line-height: 1.7; font-family: Source Sans Pro; padding-left: 5px;",
          HTML("
            <span style='display:inline-block;margin-right:20px;'>&#128269; Browse and filter curated research data</span>
            <span style='display:inline-block;margin-right:20px;'>&#128202; Interactive visualizations and statistics</span>
            <span style='display:inline-block;margin-right:20px;'>&#129302; AI-powered Chat-Radbio assistant</span>
            <span style='display:inline-block;margin-right:5px;'>&#127759; Global collaboration platform</span>
          "))
      )
    )
  ),
  fluidRow(
    column(width = 3, align = "center",
      tab_voronoys(
        texto = "Multi-omics Data Integration Module",
        cor = "#098ebb", icon = "brasil.png", id = "analise_geral"
      )
    ),
    column(width = 3, align = "center",
      tab_voronoys(
        texto = "Clinical Samples and Biological Resources",
        cor = "#fdc23a", icon = "flag.png", id = "analise_partidos"
      )
    ),
    column(width = 3, align = "center",
      tab_voronoys(
        texto = "ChatRaBio and Prognostic Model Module",
        cor = "#e96449", icon = "person.png", id = "analise_candidatos"
      )
    ),
    column(width = 3, align = "center",
      tab_voronoys(
        texto = "About us",
        cor = "#818286", icon = "sobre.png", id = "sobre"
      )
    )
  ),
  fluidRow(
    column(width = 3,
      div(class = "chart-card",
        withSpinner(plotlyOutput("home_chart_tumor_type", height = "300px"), type = 4, color = "#098ebb")
      )
    ),
    column(width = 3,
      div(class = "chart-card",
        withSpinner(plotlyOutput("home_chart_radiation_type", height = "300px"), type = 4, color = "#098ebb")
      )
    ),
    column(width = 3,
      div(class = "chart-card",
        withSpinner(plotlyOutput("home_chart_factor_type", height = "300px"), type = 4, color = "#098ebb")
      )
    ),
    column(width = 3,
      div(class = "chart-card",
        withSpinner(plotlyOutput("home_chart_evidence", height = "300px"), type = 4, color = "#098ebb")
      )
    )
  )
)
