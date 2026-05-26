clinical_tab <- tabPanel(
  title = "Clinical",
  value = "clinical",
  hr(),
  div(class = "filter-bar",
    fluidRow(
      column(width = 6,
        pickerInput(
          inputId = "clinical_tumor_type",
          label = "Tumor Type",
          choices = tumor_types,
          selected = tumor_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10),
          multiple = TRUE
        )
      ),
      column(width = 6,
        pickerInput(
          inputId = "clinical_factor_type",
          label = "Factor Type",
          choices = factor_types,
          selected = factor_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10),
          multiple = TRUE
        )
      )
    ),
    fluidRow(
      column(width = 12, align = "center",
        actionBttn(
          inputId = "clinical_reset",
          label = "Reset",
          style = "fill",
          color = "danger",
          icon = icon("refresh"),
          size = "sm"
        )
      )
    )
  ),
  br(),
  p(style = "color: #888; font-size: 13px; margin: 5px 0 15px 5px;",
    "Charts update automatically when filters change."),
  div(class = "section-title", "Clinical Analysis"),
  hr(class = "section-divider"),
  fluidRow(
    column(width = 6,
      div(class = "chart-card",
        withSpinner(plotlyOutput("clinical_effect", height = "400px"), type = 4, color = "#fdc23a")
      )
    ),
    column(width = 6,
      div(class = "chart-card",
        withSpinner(plotlyOutput("clinical_evidence_tumor", height = "400px"), type = 4, color = "#fdc23a")
      )
    )
  )
)
