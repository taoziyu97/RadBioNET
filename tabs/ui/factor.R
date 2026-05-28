factor_tab <- tabPanel(
  title = NULL,
  value = "factor_detail",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(class = "factor-page",
        div(class = "factor-header",
          div(class = "factor-header-row",
            uiOutput("factor_header"),
            actionButton("factor_back_data", "Back to Data",
              icon = icon("arrow-left"), class = "btn btn-default btn-sm")
          )
        ),
        uiOutput("factor_links"),
        div(class = "section-title", "Overview"),
        hr(class = "section-divider"),
        fluidRow(class = "factor-stats",
          column(3, div(class = "stat-card",
            div(class = "stat-value", textOutput("factor_stat_papers")),
            div(class = "stat-label", "Papers")
          )),
          column(3, div(class = "stat-card",
            div(class = "stat-value", textOutput("factor_stat_cancers")),
            div(class = "stat-label", "Cancer Types")
          )),
          column(3, div(class = "stat-card",
            div(class = "stat-value", textOutput("factor_stat_years")),
            div(class = "stat-label", "Year Range")
          )),
          column(3, div(class = "stat-card",
            div(class = "stat-value", textOutput("factor_stat_evidence")),
            div(class = "stat-label", "Evidence Types")
          ))
        ),
        br(),
        div(class = "section-title", "Distributions"),
        hr(class = "section-divider"),
        fluidRow(class = "factor-charts",
          column(width = 7,
            div(class = "chart-card",
              h5(class = "factor-chart-title", icon("bar-chart"), " Cancer Type Distribution"),
              plotlyOutput("factor_cancer_plot", height = "240px")
            )
          ),
          column(width = 5,
            div(class = "chart-card",
              h5(class = "factor-chart-title", icon("pie-chart"), " Direction Distribution"),
              plotlyOutput("factor_dir_plot", height = "240px")
            )
          )
        ),
        br(),
        div(class = "section-title", "Additional Statistics"),
        hr(class = "section-divider"),
        div(class = "factor-extra",
          fluidRow(
            column(width = 12,
              div(class = "chart-card",
                h5(class = "factor-chart-title", "Top Cancer Subtypes"),
                uiOutput("factor_top_subtypes")
              )
            )
          ),
          fluidRow(
            column(width = 6,
              div(class = "chart-card",
                h5(class = "factor-chart-title", "Evidence Type Distribution"),
                plotlyOutput("factor_evidence_plot", height = "180px")
              )
            )
          )
        ),
        br(),
        div(class = "section-title", "Related Papers"),
        hr(class = "section-divider"),
        div(class = "factor-table",
          div(class = "factor-table-wrap",
            DTOutput("factor_papers")
          )
        )
      )
    )
  )
)
