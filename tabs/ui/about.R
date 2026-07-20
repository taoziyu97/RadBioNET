about_tab <- tabPanel(
  title = "About us",
  value = "about",
  tags$head(
    tags$script(HTML("
      $(function() {
        $('#changelog-accordion .collapse').each(function() {
          var icon = $(this).closest('.panel').find('.chevron-icon');
          if ($(this).hasClass('in')) {
            icon.removeClass('fa-chevron-right').addClass('fa-chevron-down');
          } else {
            icon.removeClass('fa-chevron-down').addClass('fa-chevron-right');
          }
        });
      });
      $(document).on('shown.bs.collapse', function(e) {
        $(e.target).closest('.panel').find('.chevron-icon').removeClass('fa-chevron-right').addClass('fa-chevron-down');
      });
      $(document).on('hidden.bs.collapse', function(e) {
        $(e.target).closest('.panel').find('.chevron-icon').removeClass('fa-chevron-down').addClass('fa-chevron-right');
      });
    "))
  ),
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 28px 35px; margin-top: 6px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h1(style = "margin: 0 0 8px 0; font-size: 26px; font-weight: 700; color: #1a5276;",
          "About RadBioNet"),
        p(style = "margin: 0 0 10px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          HTML("<b>RadBioNet</b> (Radiation Biology Network) is a curated database and interactive platform supporting the global radiation oncology research community.")),
        p(style = "margin: 0 0 10px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          HTML("<b>RadBioNet was developed by the Department of Radiation Oncology, Ruijin Hospital, Shanghai Jiao Tong University School of Medicine, Shanghai, China.</b>")),
        p(style = "margin: 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          "Our mission is to provide a comprehensive, curated database of factors associated with radiation sensitivity and resistance in cancer, supporting the global radiation oncology research community."),
        p(style = "margin: 12px 0 0 0; font-size: 13px; color: #5d6d7e; line-height: 1.6;",
          icon("calendar"), HTML(" <b>V1.0 first published:</b> June 18, 2026"))
      )
    )
  ),
  fluidRow(
    column(width = 10, offset = 1,
      div(class = "section-title", "Changelog"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 20px;",
        div(class = "panel-group", id = "changelog-accordion",
          style = "margin-bottom: 0;",

          # ---- V1.0 release (May-July 2026) ----
          div(class = "panel panel-default", style = "border-color: #d0e8f0; border-radius: 8px; margin-bottom: 8px;",
            div(class = "panel-heading", style = "background: #f0f7ff; padding: 10px 15px; cursor: pointer;",
              `data-toggle` = "collapse", `data-parent` = "#changelog-accordion", href = "#changelog-v1-0",
              h4(class = "panel-title", style = "font-size: 14px; font-weight: 700; color: #1a5276;",
                icon("chevron-right", class = "chevron-icon"), " V1.0  —  First Public Release"),
              p(style = "margin: 2px 0 0 0; font-size: 12px; color: #888;", "Released June 18, 2026 · Development and deployment milestones from May to July 2026")
            ),
            div(id = "changelog-v1-0", class = "panel-collapse collapse",
              div(class = "panel-body", style = "padding: 12px 18px; font-size: 13px; color: #444; line-height: 1.8;",
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Release &amp; Data"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("<b>Release:</b> First public release of RadBioNet as a curated radiation-sensitivity and resistance database")),
                  tags$li(HTML("<b>Data:</b> Published 15,730 curated records across 29 fields")),
                  tags$li(HTML("<b>Data:</b> Corrected particle classifications, including 178 proton records and 1,062 X-ray records")),
                  tags$li(HTML("<b>Data:</b> Added 2,123 toxicity entries classified into 15 endpoint categories"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "New Features"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("<b>New:</b> Toxicity Endpoint filter added to Data page sidebar")),
                  tags$li(HTML("<b>New:</b> Toxicity Endpoint Distribution bar chart on Analysis page")),
                  tags$li(HTML("<b>New:</b> Chat-Radbio settings (backend, API URL, key, model) persist in browser localStorage")),
                  tags$li(HTML("<b>New:</b> Chat-Radbio chat history persists in localStorage (last 20 messages)")),
                  tags$li(HTML("<b>New:</b> Resource Hub with curated external resources, including RadioPharm")),
                  tags$li(HTML("<b>New:</b> Collapsible release notes on the About us page"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Access, Deployment &amp; Reliability"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("<b>Access:</b> Added a China-accessible deployment path and removed blocked Google Fonts")),
                  tags$li(HTML("<b>Deployment:</b> Deployed a dedicated Shiny instance on Alibaba Cloud Hong Kong with Nginx and WebSocket support")),
                  tags$li(HTML("<b>Security:</b> Enabled HTTPS with a Let's Encrypt certificate and automatic renewal")),
                  tags$li(HTML("<b>Reliability:</b> Added automatic service startup/restart, swap space, and a fallback deployment route"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Interface &amp; Bug Fixes"),
                tags$ul(style = "margin: 0; padding-left: 18px;",
                  tags$li(HTML("<b>Redesign:</b> Updated About us, Chat-Radbio, Resource Hub, and responsive navigation")),
                  tags$li(HTML("<b>Fix:</b> Restored homepage statistical charts and Analysis-page dose-distribution charts")),
                  tags$li(HTML("<b>Fix:</b> Corrected particle-filter behavior and Cancer Type summary counts")),
                  tags$li(HTML("<b>Fix:</b> Improved Chat-Radbio settings persistence and credential reuse")),
                  tags$li(HTML("<b>Fix:</b> Standardized analysis-table column names for reliable data loading"))
                )
              )
            )
          ),

          # ---- 2025 ----
          div(class = "panel panel-default", style = "border-color: #d0e8f0; border-radius: 8px;",
            div(class = "panel-heading", style = "background: #f0f7ff; padding: 10px 15px; cursor: pointer;",
              `data-toggle` = "collapse", `data-parent` = "#changelog-accordion", href = "#changelog-2025",
              h4(class = "panel-title", style = "font-size: 14px; font-weight: 700; color: #1a5276;",
                icon("chevron-down", class = "chevron-icon"), " 2025  —  Project Initiation &amp; Development"),
              p(style = "margin: 2px 0 0 0; font-size: 12px; color: #888;", "Topic selection, domain registration, infrastructure, data curation, app development")
            ),
            div(id = "changelog-2025", class = "panel-collapse collapse in",
              `aria-expanded` = "true",
              div(class = "panel-body", style = "padding: 12px 18px; font-size: 13px; color: #444; line-height: 1.8;",
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Project Planning &amp; Infrastructure"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("Project inception: radiation sensitivity &amp; resistance factor database for the radiation oncology community")),
                  tags$li(HTML("Topic selection &mdash; systematic review of factors modulating radiation response in cancer")),
                  tags$li(HTML("Registered domain <b>radbionet.com</b>")),
                  tags$li(HTML("Server infrastructure: Alibaba Cloud ECS + OSS setup")),
                  tags$li(HTML("Chose R Shiny as the web application framework")),
                  tags$li(HTML("Set up Git version control and development workflow"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Data Curation"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("Designed database schema (29 columns across 15,730 records)")),
                  tags$li(HTML("Systematic literature search across PubMed, Web of Science, and Cochrane Library")),
                  tags$li(HTML("Developed data extraction pipeline and quality control workflow")),
                  tags$li(HTML("Factor categorization: Gene/Protein, Drug, Pathway, Immune factor, Cytokine, etc.")),
                  tags$li(HTML("Particle evidence level classification: Direct, Paper-level, Title-level, Contextual, Multi-particle")),
                  tags$li(HTML("Knowledge graph construction: factor-factor and factor-cancer type relationships"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Application Development"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("Designed and implemented multi-tab Shiny UI with custom CSS theme")),
                  tags$li(HTML("Developed Data page with 6-filter sidebar, searchable data table, and statistics cards")),
                  tags$li(HTML("Developed Analysis page with research timeline, modality/equipment distribution, dose distribution, and knowledge graph")),
                  tags$li(HTML("Developed Chat-RadBio: AI assistant with Ollama and OpenAI-compatible API support")),
                  tags$li(HTML("Developed Factor detail view with external links (GeneCards, NCBI, UniProt, STRING, DrugBank, DepMap)")),
                  tags$li(HTML("Designed responsive layout with gradient heroes, chart cards, and modern color scheme")),
                  tags$li(HTML("Custom font stack, branded color palette, and consistent UI component library"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Deployment"),
                tags$ul(style = "margin: 0; padding-left: 18px;",
                  tags$li(HTML("Deployed Shiny app on shinyapps.io")),
                  tags$li(HTML("Set up landing page on Netlify with custom domain")),
                  tags$li(HTML("Configured DNS, SSL certificates, and CDN")),
                  tags$li(HTML("Implemented CI/CD workflow for seamless updates"))
                )
              )
            )
          )
        )
      ),
      br()
    )
  ),
  fluidRow(
    column(width = 10, offset = 1,
      div(class = "section-title", "Contact"),
      hr(class = "section-divider"),
      div(class = "chart-card", style = "padding: 20px; text-align: center;",
        p(style = "font-size: 14px; color: #555; margin: 0;",
          icon("envelope"), " Contact us at ",
          tags$a(href = "mailto:taozy@sjtu.edu.cn", "taozy@sjtu.edu.cn")
        )
      ),
      br()
    )
  )
)
