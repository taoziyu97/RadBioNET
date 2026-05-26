home <- tabPanel(
  title = "Home",
  value = "home",
  hr(),
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
    column(width = 12,
      wellPanel(
        HTML("<h4 style='margin:0'><b>RadBioNet</b> (Radiation Biology Network) — Department of Radiation Oncology, <span style='color:#19509A;font-weight:bold'>Ruijin Hospital</span>, Shanghai JiaoTong University. A curated database of factors associated with radiation sensitivity and resistance in cancer.</h4>")
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
