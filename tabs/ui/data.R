data_tab <- tabPanel(
  title = "Data",
  value = "data",
  hr(),
  div(class = "filter-bar",
    fluidRow(
      column(width = 6,
        pickerInput(
          inputId = "filter_tumor_type",
          label = "Tumor Type",
          choices = tumor_types,
          selected = tumor_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10),
          multiple = TRUE
        )
      ),
      column(width = 6,
        pickerInput(
          inputId = "filter_radiation_type",
          label = "Radiation Type",
          choices = radiation_types,
          selected = radiation_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10),
          multiple = TRUE
        )
      )
    ),
    fluidRow(
      column(width = 5,
        pickerInput(
          inputId = "filter_factor_type",
          label = "Factor Type",
          choices = factor_types,
          selected = factor_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10),
          multiple = TRUE
        )
      ),
      column(width = 5,
        pickerInput(
          inputId = "filter_evidence",
          label = "Evidence Level",
          choices = evidence_levels,
          selected = evidence_levels,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 10),
          multiple = TRUE
        )
      ),
      column(width = 2,
        br(),
        actionBttn(
          inputId = "btn_reset",
          label = "Reset",
          style = "fill",
          color = "danger",
          icon = icon("refresh"),
          size = "sm",
          block = TRUE
        )
      )
    )
  ),
  div(class = "section-title", "Database Records"),
  hr(class = "section-divider"),
  fluidRow(
    column(width = 12,
      div(class = "chart-card",
        withSpinner(DTOutput("data_table"), type = 4, color = "#098ebb")
      )
    )
  )
)
