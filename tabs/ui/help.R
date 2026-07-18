help_tab <- tabPanel(
  title = "Help",
  value = "help",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(
        style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 28px 35px; margin-top: 6px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h1(
          style = "margin: 0 0 8px 0; font-size: 26px; font-weight: 700; color: #1a5276;",
          icon("question-circle"), " Help & User Guide"
        ),
        p(
          style = "margin: 0 0 14px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          "Learn how to use RadBioNET for database browsing, multidimensional filtering, evidence review, interactive analysis, knowledge-graph exploration, data export, and Chat-Radbio."
        ),
        div(
          style = "display: flex; flex-wrap: wrap; gap: 10px;",
          tags$a(
            href = "pdf/RadBioNET_User_Guide_V1.2.pdf?v=20260719-0224",
            target = "_blank",
            class = "btn btn-primary",
            style = "background-color: #098ebb; border-color: #098ebb;",
            icon("external-link"), " Read online"
          ),
          tags$a(
            href = "pdf/RadBioNET_User_Guide_V1.2.pdf?v=20260719-0224",
            download = "RadBioNET_User_Guide_V1.2.pdf",
            class = "btn btn-default",
            icon("download"), " Download PDF"
          )
        )
      )
    )
  ),
  fluidRow(
    column(width = 10, offset = 1,
      div(class = "section-title", "RadBioNET User Guide"),
      hr(class = "section-divider"),
      div(
        class = "chart-card",
        style = "padding: 22px 26px;",
        fluidRow(
          column(
            width = 8,
            h3(
              style = "margin-top: 0; color: #1a5276; font-weight: 700;",
              "Supplementary Information - Version 1.2"
            ),
            p(
              style = "font-size: 14px; color: #555; line-height: 1.7;",
              "This 22-page guide provides a structured introduction to RadBioNET, recommended research workflows, field definitions, worked examples, and troubleshooting guidance."
            ),
            tags$ul(
              style = "font-size: 13px; color: #555; line-height: 1.9; padding-left: 20px; margin-bottom: 0;",
              tags$li("System access, interface structure, and navigation"),
              tags$li("Data browsing, combined filters, evidence inspection, and export"),
              tags$li("Factor-level evidence pages and recommended review sequence"),
              tags$li("Interactive analyses and Knowledge Graph"),
              tags$li("Chat-Radbio configuration and Resource Hub"),
              tags$li("Data dictionary, worked examples, and troubleshooting")
            )
          ),
          column(
            width = 4,
            div(
              style = "background: #f7fafc; border: 1px solid #dce7ed; border-radius: 10px; padding: 18px 20px; margin-top: 4px;",
              p(style = "margin: 0 0 10px 0; color: #1a5276; font-weight: 700;", icon("file-pdf-o"), " Document details"),
              p(style = "margin: 5px 0; font-size: 13px; color: #555;", strong("Version: "), "1.2"),
              p(style = "margin: 5px 0; font-size: 13px; color: #555;", strong("Pages: "), "22"),
              p(style = "margin: 5px 0; font-size: 13px; color: #555;", strong("Format: "), "PDF"),
              p(style = "margin: 5px 0 0 0; font-size: 13px; color: #555;", strong("Language: "), "English")
            )
          )
        )
      ),
      br()
    )
  )
)
