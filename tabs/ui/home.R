home <- tabPanel(
  title = "Home",
  value = "home",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 30px 35px 25px 35px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h1(style = "margin: 0 0 15px 0; font-size: 26px; font-weight: 700; color: #1a5276;",
          "RadBioNet"),
        p(style = "margin: 0 0 14px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          HTML("<b>RadBioNet</b> (Radiation Biology Network) is a curated database and interactive platform developed by the <span style='color:#19509A;font-weight:bold'>Department of Radiation Oncology at Ruijin Hospital</span>, Shanghai JiaoTong University School of Medicine.")),
        p(style = "margin: 0 0 18px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          "The platform serves as a central hub for collecting, visualizing, and exploring factors associated with radiation sensitivity and resistance in cancer, supporting the global radiation oncology research community."),
        fluidRow(
          column(width = 3,
            div(style = "background:#fff;border-radius:10px;padding:12px 8px;text-align:center;border:1px solid #e0eef5;margin-bottom:5px;",
              div(style = "font-size:22px;margin-bottom:4px;", "&#128269;"),
              div(style = "font-size:13px;color:#2c3e50;font-weight:600;", "Browse & Filter"),
              div(style = "font-size:11px;color:#888;", "Curated research data")
            )
          ),
          column(width = 3,
            div(style = "background:#fff;border-radius:10px;padding:12px 8px;text-align:center;border:1px solid #e0eef5;margin-bottom:5px;",
              div(style = "font-size:22px;margin-bottom:4px;", "&#128202;"),
              div(style = "font-size:13px;color:#2c3e50;font-weight:600;", "Visualizations"),
              div(style = "font-size:11px;color:#888;", "Interactive charts & tables")
            )
          ),
          column(width = 3,
            div(style = "background:#fff;border-radius:10px;padding:12px 8px;text-align:center;border:1px solid #e0eef5;margin-bottom:5px;",
              div(style = "font-size:22px;margin-bottom:4px;", "&#129302;"),
              div(style = "font-size:13px;color:#2c3e50;font-weight:600;", "AI Assistant"),
              div(style = "font-size:11px;color:#888;", "Chat-Radbio Q&A")
            )
          ),
          column(width = 3,
            div(style = "background:#fff;border-radius:10px;padding:12px 8px;text-align:center;border:1px solid #e0eef5;margin-bottom:5px;",
              div(style = "font-size:22px;margin-bottom:4px;", "&#127759;"),
              div(style = "font-size:13px;color:#2c3e50;font-weight:600;", "Collaboration"),
              div(style = "font-size:11px;color:#888;", "Global research network")
            )
          )
        )
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
