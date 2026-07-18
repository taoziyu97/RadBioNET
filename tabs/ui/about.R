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
          icon("calendar"), HTML(" <b>Version 1.2 first published:</b> July 17, 2026"))
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

          # ---- 2026-07 ----
          div(class = "panel panel-default", style = "border-color: #d0e8f0; border-radius: 8px; margin-bottom: 8px;",
            div(class = "panel-heading", style = "background: #f0f7ff; padding: 10px 15px; cursor: pointer;",
              `data-toggle` = "collapse", `data-parent` = "#changelog-accordion", href = "#changelog-2026-07",
              h4(class = "panel-title", style = "font-size: 14px; font-weight: 700; color: #1a5276;",
                icon("chevron-right", class = "chevron-icon"), " July 2026  —  v1.2"),
              p(style = "margin: 2px 0 0 0; font-size: 12px; color: #888;", "Hong Kong deployment, HTTPS, faster China access, chart compatibility fix")
            ),
            div(id = "changelog-2026-07", class = "panel-collapse collapse",
              div(class = "panel-body", style = "padding: 12px 18px; font-size: 13px; color: #444; line-height: 1.8;",
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Infrastructure &amp; Deployment"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("<b>New:</b> Deployed a dedicated RadBioNET Shiny instance on an Alibaba Cloud Hong Kong server for faster access from China")),
                  tags$li(HTML("<b>Infra:</b> Added Nginx reverse proxy with WebSocket support and a systemd service with automatic startup and restart")),
                  tags$li(HTML("<b>Infra:</b> Added <code>hk-app.radbionet.com</code> as a direct DNS endpoint for the Hong Kong deployment")),
                  tags$li(HTML("<b>Security:</b> Enabled HTTPS with a Let's Encrypt certificate and automatic renewal")),
                  tags$li(HTML("<b>Reliability:</b> Added 2 GB swap space for stable package installation and operation on the validation server")),
                  tags$li(HTML("<b>Routing:</b> Updated the Netlify landing page at <code>radbionet.com</code> to load the Hong Kong Shiny endpoint; the previous shinyapps.io/Cloudflare Worker route remains available as a fallback"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Bug Fixes"),
                tags$ul(style = "margin: 0; padding-left: 18px;",
                  tags$li(HTML("<b>Fix:</b> Upgraded Plotly, HTMLWidgets, DT, dplyr, tidyr, ggplot2, and scales to resolve homepage statistical charts remaining in a loading state"))
                )
              )
            )
          ),

          # ---- 2026-06 ----
          div(class = "panel panel-default", style = "border-color: #d0e8f0; border-radius: 8px; margin-bottom: 8px;",
            div(class = "panel-heading", style = "background: #f0f7ff; padding: 10px 15px; cursor: pointer;",
              `data-toggle` = "collapse", `data-parent` = "#changelog-accordion", href = "#changelog-2026-06",
              h4(class = "panel-title", style = "font-size: 14px; font-weight: 700; color: #1a5276;",
                icon("chevron-right", class = "chevron-icon"), " June 2026  —  v1.1"),
              p(style = "margin: 2px 0 0 0; font-size: 12px; color: #888;", "Toxicity endpoints, China CDN, chat persistence, multi-bug fixes")
            ),
            div(id = "changelog-2026-06", class = "panel-collapse collapse",
              div(class = "panel-body", style = "padding: 12px 18px; font-size: 13px; color: #444; line-height: 1.8;",
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Infrastructure &amp; Deployment"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("<b>New:</b> Cloudflare Worker proxy deployed at <code>app.radbionet.com</code> for China accessibility &mdash; routes all RadBioNET traffic through Cloudflare HK node")),
                  tags$li(HTML("<b>Infra:</b> Custom domain <code>app.radbionet.com</code> bound to Worker, replacing direct shinyapps.io access in iframe")),
                  tags$li(HTML("<b>Infra:</b> Deployed updated index.html to Netlify with Worker proxy URL")),
                  tags$li(HTML("<b>Infra:</b> fread column name parsing fixed for all analysis CSVs (<code>check.names = TRUE</code>)"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "New Features"),
                tags$ul(style = "margin: 0 0 10px 0; padding-left: 18px;",
                  tags$li(HTML("<b>New:</b> Toxicity endpoint extraction &mdash; 2,123 entries classified into 15 endpoint categories (Rectal/GI, Dermatitis, Necrosis, Hematologic, Fibrosis, etc.) from free-text supporting sentences")),
                  tags$li(HTML("<b>New:</b> Toxicity Endpoint filter added to Data page sidebar")),
                  tags$li(HTML("<b>New:</b> Toxicity Endpoint Distribution bar chart on Analysis page")),
                  tags$li(HTML("<b>New:</b> Chat-Radbio settings (backend, API URL, key, model) persist in browser localStorage")),
                  tags$li(HTML("<b>New:</b> Chat-Radbio chat history persists in localStorage (last 20 messages)")),
                  tags$li(HTML("<b>New:</b> Collapsible changelog with version history on About Us page")),
                  tags$li(HTML("<b>New:</b> RadioPharm &mdash; comprehensive radiopharmaceutical database &mdash; added to Resource Hub"))
                ),
                h5(style = "font-weight: 700; color: #1a5276; margin: 0 0 6px 0;", "Bug Fixes"),
                tags$ul(style = "margin: 0; padding-left: 18px;",
                  tags$li(HTML("<b>Fix:</b> Dose Distribution (Modality &amp; Equipment) charts on Analysis page not displaying")),
                  tags$li(HTML("<b>Fix:</b> Particle type filter logic &mdash; empty selection now shows all data, specific selection filters correctly")),
                  tags$li(HTML("<b>Fix:</b> Cancer Type stat card count corrected (was counting semicolon-separated values as distinct entries)")),
                  tags$li(HTML("<b>Fix:</b> Removed robot icon from Chat-Radbio header")),
                  tags$li(HTML("<b>Fix:</b> Chat-Radbio settings reopening no longer requires re-entering credentials"))
                )
              )
            )
          ),

          # ---- 2026-05 ----
          div(class = "panel panel-default", style = "border-color: #d0e8f0; border-radius: 8px; margin-bottom: 8px;",
            div(class = "panel-heading", style = "background: #f0f7ff; padding: 10px 15px; cursor: pointer;",
              `data-toggle` = "collapse", `data-parent` = "#changelog-accordion", href = "#changelog-2026-05",
              h4(class = "panel-title", style = "font-size: 14px; font-weight: 700; color: #1a5276;",
                icon("chevron-right", class = "chevron-icon"), " May 2026  —  v1.0 Release &amp; China Accessibility"),
              p(style = "margin: 2px 0 0 0; font-size: 12px; color: #888;", "Public launch, China CDN, UI redesign, data correction")
            ),
            div(id = "changelog-2026-05", class = "panel-collapse collapse",
              div(class = "panel-body", style = "padding: 12px 18px; font-size: 13px; color: #444; line-height: 1.8;",
                tags$ul(style = "margin: 0; padding-left: 18px;",
                  tags$li(HTML("<b>v1.0 Release:</b> First public release of RadBioNet on shinyapps.io")),
                  tags$li(HTML("<b>Infra:</b> radbionet.com DNS migrated to Cloudflare for China accessibility")),
                  tags$li(HTML("<b>Infra:</b> Netlify landing page with iframe to Shiny app")),
                  tags$li(HTML("<b>New:</b> Resource Hub page with 10 categories (~40 curated resources)")),
                  tags$li(HTML("<b>Redesign:</b> About Us page with gradient hero block and chart-card layout")),
                  tags$li(HTML("<b>Redesign:</b> Chat-Radbio intro hero block added")),
                  tags$li(HTML("<b>Fix:</b> Mobile navbar padding, divider lines, and font-weight improvements")),
                  tags$li(HTML("<b>Fix:</b> Removed Google Fonts (blocked in China) &rarr; system-ui font stack")),
                  tags$li(HTML("<b>Data:</b> Proton data corrected &mdash; 178 Proton, 1,062 X-ray, 13,822 (none)"))
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
