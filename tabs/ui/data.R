data_tab <- tabPanel(
  title = "Data",
  value = "data",
  hr(),
  fluidRow(
    column(width = 3,
      div(class = "filter-sidebar",
        h5(style = "font-weight: 700; color: #333; margin-top: 0; margin-bottom: 12px;",
           icon("filter"), " Filters"),
        pickerInput("filter_cancer_type", "Cancer Type",
          choices = cancer_types, selected = cancer_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_radiation_type", "Radiation Type",
          choices = radiation_types, selected = radiation_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_factor_type", "Factor Type",
          choices = factor_types, selected = factor_types,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_direction", "Direction",
          choices = directions, selected = directions,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_evidence_type", "Evidence Type",
          choices = evidence_types, selected = evidence_types,
          options = list(`actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_quality", "Quality Flag",
          choices = quality_flags, selected = quality_flags,
          options = list(`actions-box` = TRUE, size = 5),
          multiple = TRUE),
        pickerInput("filter_year", "Publication Year",
          choices = years, selected = years,
          options = list(`actions-box` = TRUE, size = 8),
          multiple = TRUE),
        br(),
        div(style = "text-align: center;",
          actionBttn("btn_reset", "Reset All", style = "fill",
            color = "danger", icon = icon("refresh"), size = "sm")
        )
      )
    ),
    column(width = 9,
      fluidRow(
        column(width = 3,
          div(class = "stat-card",
            div(class = "stat-value", textOutput("stat_total")),
            div(class = "stat-label", "Total Records")
          )
        ),
        column(width = 3,
          div(class = "stat-card",
            div(class = "stat-value", textOutput("stat_factors")),
            div(class = "stat-label", "Unique Factors")
          )
        ),
        column(width = 3,
          div(class = "stat-card",
            div(class = "stat-value", textOutput("stat_cancers")),
            div(class = "stat-label", "Cancer Types")
          )
        ),
        column(width = 3,
          div(class = "stat-card",
            div(class = "stat-value", textOutput("stat_years")),
            div(class = "stat-label", "Year Range")
          )
        )
      ),
      br(),
      div(class = "section-title", "Database Records"),
      hr(class = "section-divider"),
      div(class = "chart-card",
        withSpinner(DTOutput("data_table"), type = 4, color = "#098ebb")
      )
    )
  )
)
