analysis_tab <- tabPanel(
  title = "Analysis",
  value = "analysis",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(class = "section-title", "Factor Research Timeline"),
      hr(class = "section-divider"),
      fluidRow(
        column(width = 12,
          pickerInput("analysis_factors", "Select Factors",
            choices = NULL, multiple = TRUE,
            options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10, `selected-text-format` = "count > 3")
          )
        )
      ),
      fluidRow(
        column(width = 12,
          div(class = "chart-card",
            withSpinner(plotlyOutput("analysis_timeline", height = "400px"), type = 4, color = "#098ebb")
          )
        )
      ),
      fluidRow(
        column(width = 12,
          div(class = "chart-card",
            withSpinner(DTOutput("analysis_trends_table"), type = 4, color = "#098ebb")
          )
        )
      ),
      br(),
      div(class = "section-title", "Modality & Equipment"),
      hr(class = "section-divider"),
      fluidRow(
        column(width = 6,
          div(class = "chart-card",
            withSpinner(plotlyOutput("analysis_modality", height = "350px"), type = 4, color = "#098ebb")
          )
        ),
        column(width = 6,
          div(class = "chart-card",
            withSpinner(plotlyOutput("analysis_device", height = "350px"), type = 4, color = "#098ebb")
          )
        )
      ),
      br(),
      div(class = "section-title", "Dose Distribution"),
      hr(class = "section-divider"),
      fluidRow(
        column(width = 6,
          div(class = "chart-card",
            withSpinner(plotlyOutput("analysis_dose_model", height = "350px"), type = 4, color = "#098ebb")
          )
        ),
        column(width = 6,
          div(class = "chart-card",
            withSpinner(plotlyOutput("analysis_dose_particle", height = "350px"), type = 4, color = "#098ebb")
          )
        )
      ),
      br(),
      div(class = "section-title", "Toxicity Endpoint Distribution"),
      hr(class = "section-divider"),
      fluidRow(
        column(width = 12,
          div(class = "chart-card",
            withSpinner(plotlyOutput("analysis_toxicity_endpoint", height = "400px"), type = 4, color = "#098ebb")
          )
        )
      ),
      br(),
      div(class = "section-title", "Knowledge Graph"),
      hr(class = "section-divider"),
      fluidRow(
        column(width = 12,
          div(class = "chart-card",
            withSpinner(visNetworkOutput("analysis_knowledge_graph", height = "600px"), type = 4, color = "#098ebb")
          )
        )
      )
    )
  )
)
