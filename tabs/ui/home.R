home <- tabPanel(
  title = "Home",
  value = "home",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 28px 35px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h1(style = "margin: 0 0 12px 0; font-size: 26px; font-weight: 700; color: #1a5276;",
          "RadBioNet"),
        p(style = "margin: 0 0 10px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          HTML("<b>RadBioNet</b> (Radiation Biology Network) is a curated database and interactive platform developed by the <span style='color:#19509A;font-weight:bold'>Department of Radiation Oncology at Ruijin Hospital</span>, Shanghai JiaoTong University School of Medicine.")),
        p(style = "margin: 0 0 5px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          "The platform serves as a central hub for collecting, visualizing, and exploring factors associated with radiation sensitivity and resistance in cancer, supporting the global radiation oncology research community.")
      )
    )
  ),
  fluidRow(
    column(width = 3,
      div(class = "feature-card", onclick = "Shiny.setInputValue('analise_geral', 'click', {priority: 'event'});",
        div(class = "feature-icon", "&#128269;"),
        div(class = "feature-title", "Browse & Filter"),
        div(class = "feature-desc", "Curated research data on radiation sensitivity and resistance factors")
      )
    ),
    column(width = 3,
      div(class = "feature-card", onclick = "Shiny.setInputValue('analise_partidos', 'click', {priority: 'event'});",
        div(class = "feature-icon", "&#128202;"),
        div(class = "feature-title", "Visualizations"),
        div(class = "feature-desc", "Interactive charts and statistics for data exploration")
      )
    ),
    column(width = 3,
      div(class = "feature-card", onclick = "Shiny.setInputValue('analise_candidatos', 'click', {priority: 'event'});",
        div(class = "feature-icon", "&#129302;"),
        div(class = "feature-title", "AI Assistant"),
        div(class = "feature-desc", "Chat-Radbio Q&A powered by large language models")
      )
    ),
    column(width = 3,
      div(class = "feature-card", onclick = "Shiny.setInputValue('sobre', 'click', {priority: 'event'});",
        div(class = "feature-icon", "&#127759;"),
        div(class = "feature-title", "Collaboration"),
        div(class = "feature-desc", "Global research network for radiation oncology")
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
