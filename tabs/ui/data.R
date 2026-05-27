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
          choices = cancer_type_choices, selected = cancer_type_choices,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_particle_type", "Particle Type",
          choices = particle_type_choices, selected = particle_type_choices,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_factor_type", "Factor Type",
          choices = factor_type_choices, selected = factor_type_choices,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_direction", "Direction",
          choices = direction_choices, selected = direction_choices,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_evidence_type", "Evidence Type",
          choices = evidence_type_choices, selected = evidence_type_choices,
          options = list(`live-search` = TRUE, `actions-box` = TRUE, size = 8),
          multiple = TRUE),
        pickerInput("filter_quality", "Quality Flag",
          choices = quality_flag_choices, selected = quality_flag_choices,
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
      div(style = "font-size: 12px; color: #888; margin: 2px 0 8px 0;",
        icon("info-circle"), " Click on any ", strong("Factor"), " name to view detailed information"),
      hr(class = "section-divider"),
      div(class = "chart-card",
        withSpinner(DTOutput("data_table"), type = 4, color = "#098ebb")
      )
    )
  )
)
