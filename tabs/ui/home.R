home <- tabPanel(
  title = "Home",
  value = "home",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 28px 35px; margin-top: 6px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
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
    column(width = 10, offset = 1,
      fluidRow(
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3", align = "center",
          nav_block(
            title = "Browse & Filter",
            subtitle = "Curated research data on radiation sensitivity and resistance factors",
            cor = "#098ebb", icon = "brasil.png", id = "analise_geral"
          )
        ),
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3", align = "center",
          nav_block(
            title = "Visualizations",
            subtitle = "Interactive charts and statistics for data exploration",
            cor = "#fdc23a", icon = "flag.png", id = "analise_partidos"
          )
        ),
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3", align = "center",
          nav_block(
            title = "AI Assistant",
            subtitle = "Chat-Radbio Q&A powered by large language models",
            cor = "#e96449", icon = "person.png", id = "analise_candidatos"
          )
        ),
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3", align = "center",
          nav_block(
            title = "Collaboration",
            subtitle = "Global research network for radiation oncology",
            cor = "#818286", icon = "sobre.png", id = "sobre"
          )
        )
      )
    )
  ),
  fluidRow(
    column(width = 10, offset = 1,
      fluidRow(
        column(width = 4, class = "col-xs-12 col-sm-4",
          div(class = "stat-card",
            div(class = "stat-value", textOutput("home_stat_total")),
            div(class = "stat-label", "Total Records")
          )
        ),
        column(width = 4, class = "col-xs-12 col-sm-4",
          div(class = "stat-card",
            div(class = "stat-value", textOutput("home_stat_years")),
            div(class = "stat-label", "Year Range")
          )
        ),
        column(width = 4, class = "col-xs-12 col-sm-4",
          div(class = "stat-card",
            div(class = "stat-value", textOutput("home_stat_particles")),
            div(class = "stat-label", "Particle Types")
          )
        )
      ),
      br(),
      fluidRow(
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3",
          div(class = "chart-card",
            withSpinner(plotlyOutput("home_chart_tumor_type", height = "300px"), type = 4, color = "#098ebb")
          )
        ),
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3",
          div(class = "chart-card",
            withSpinner(plotlyOutput("home_chart_radiation_type", height = "300px"), type = 4, color = "#098ebb")
          )
        ),
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3",
          div(class = "chart-card",
            withSpinner(plotlyOutput("home_chart_factor_type", height = "300px"), type = 4, color = "#098ebb")
          )
        ),
        column(width = 3, class = "col-xs-12 col-sm-6 col-md-3",
          div(class = "chart-card",
            withSpinner(plotlyOutput("home_chart_evidence", height = "300px"), type = 4, color = "#098ebb")
          )
        )
      )
    )
  )
)
