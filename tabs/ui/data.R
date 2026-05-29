data_tab <- tabPanel(
  title = "Data",
  value = "data",
  hr(),
  fluidRow(
    column(width = 3,
      div(class = "filter-sidebar",
        h5(style = "font-weight: 700; color: #333; margin-top: 0; margin-bottom: 12px;",
           icon("filter"), " Filters"),
        div(class = "filter-card",
          div(style = "display: flex; align-items: center; gap: 6px;",
            tags$label("Cancer Type", style = "font-weight: 700; font-size: 13px; color: #333; margin-bottom: 0; white-space: nowrap;"),
            div(style = "flex: 1;"),
            div(style = "font-size: 11px; white-space: nowrap; flex-shrink: 0;",
              actionLink("sa_cancer_type", "Select All", style = "padding: 0;"),
              span(style = "color: #ccc; margin: 0 3px;", "|"),
              actionLink("da_cancer_type", "Deselect All", style = "padding: 0;")
            ),
            tags$a(href = "#", icon("search"), style = "color: #098ebb; font-size: 13px; text-decoration: none;",
              onclick = "$(this).hide().next('.filter-search-input').show().find('input').focus().on('blur',function(){$(this).val('').trigger('input');$(this).closest('.filter-search-input').hide().prev().show();}); return false;"),
            div(class = "filter-search-input", style = "display: none;",
              textInput("search_cancer_type", NULL, placeholder = "search...", width = "100%")
            )
          ),
          div(style = "max-height: 80px; overflow-y: auto; border: 1px solid #ddd; border-radius: 6px; padding: 4px 8px; background: #fff;",
            prettyCheckboxGroup("filter_cancer_type", NULL,
              choices = cancer_type_choices, selected = cancer_type_choices,
              shape = "curve", outline = TRUE, animation = "smooth", status = "success"
            )
          )
        ),
        div(class = "filter-card",
          div(style = "display: flex; align-items: center; gap: 6px;",
            tags$label("Particle Type", style = "font-weight: 700; font-size: 13px; color: #333; margin-bottom: 0; white-space: nowrap;"),
            div(style = "flex: 1;"),
            div(style = "font-size: 11px; white-space: nowrap; flex-shrink: 0;",
              actionLink("sa_particle_type", "Select All", style = "padding: 0;"),
              span(style = "color: #ccc; margin: 0 3px;", "|"),
              actionLink("da_particle_type", "Deselect All", style = "padding: 0;")
            ),
            tags$a(href = "#", icon("search"), style = "color: #098ebb; font-size: 13px; text-decoration: none;",
              onclick = "$(this).hide().next('.filter-search-input').show().find('input').focus().on('blur',function(){$(this).val('').trigger('input');$(this).closest('.filter-search-input').hide().prev().show();}); return false;"),
            div(class = "filter-search-input", style = "display: none;",
              textInput("search_particle_type", NULL, placeholder = "search...", width = "100%")
            )
          ),
          div(style = "max-height: 80px; overflow-y: auto; border: 1px solid #ddd; border-radius: 6px; padding: 4px 8px; background: #fff;",
            prettyCheckboxGroup("filter_particle_type", NULL,
              choices = particle_type_choices, selected = particle_type_choices,
              shape = "curve", outline = TRUE, animation = "smooth", status = "success"
            )
          )
        ),
        div(class = "filter-card",
          div(style = "display: flex; align-items: center; gap: 6px;",
            tags$label("Factor Type", style = "font-weight: 700; font-size: 13px; color: #333; margin-bottom: 0; white-space: nowrap;"),
            div(style = "flex: 1;"),
            div(style = "font-size: 11px; white-space: nowrap; flex-shrink: 0;",
              actionLink("sa_factor_type", "Select All", style = "padding: 0;"),
              span(style = "color: #ccc; margin: 0 3px;", "|"),
              actionLink("da_factor_type", "Deselect All", style = "padding: 0;")
            ),
            tags$a(href = "#", icon("search"), style = "color: #098ebb; font-size: 13px; text-decoration: none;",
              onclick = "$(this).hide().next('.filter-search-input').show().find('input').focus().on('blur',function(){$(this).val('').trigger('input');$(this).closest('.filter-search-input').hide().prev().show();}); return false;"),
            div(class = "filter-search-input", style = "display: none;",
              textInput("search_factor_type", NULL, placeholder = "search...", width = "100%")
            )
          ),
          div(style = "max-height: 80px; overflow-y: auto; border: 1px solid #ddd; border-radius: 6px; padding: 4px 8px; background: #fff;",
            prettyCheckboxGroup("filter_factor_type", NULL,
              choices = factor_type_choices, selected = factor_type_choices,
              shape = "curve", outline = TRUE, animation = "smooth", status = "success"
            )
          )
        ),
        div(class = "filter-card",
          div(style = "display: flex; align-items: center; gap: 6px;",
            tags$label("Direction", style = "font-weight: 700; font-size: 13px; color: #333; margin-bottom: 0; white-space: nowrap;"),
            div(style = "flex: 1;"),
            div(style = "font-size: 11px; white-space: nowrap; flex-shrink: 0;",
              actionLink("sa_direction", "Select All", style = "padding: 0;"),
              span(style = "color: #ccc; margin: 0 3px;", "|"),
              actionLink("da_direction", "Deselect All", style = "padding: 0;")
            ),
            tags$a(href = "#", icon("search"), style = "color: #098ebb; font-size: 13px; text-decoration: none;",
              onclick = "$(this).hide().next('.filter-search-input').show().find('input').focus().on('blur',function(){$(this).val('').trigger('input');$(this).closest('.filter-search-input').hide().prev().show();}); return false;"),
            div(class = "filter-search-input", style = "display: none;",
              textInput("search_direction", NULL, placeholder = "search...", width = "100%")
            )
          ),
          div(style = "max-height: 80px; overflow-y: auto; border: 1px solid #ddd; border-radius: 6px; padding: 4px 8px; background: #fff;",
            prettyCheckboxGroup("filter_direction", NULL,
              choices = direction_choices, selected = direction_choices,
              shape = "curve", outline = TRUE, animation = "smooth", status = "success"
            )
          )
        ),
        div(class = "filter-card",
          div(style = "display: flex; align-items: center; gap: 6px;",
            tags$label("Evidence Type", style = "font-weight: 700; font-size: 13px; color: #333; margin-bottom: 0; white-space: nowrap;"),
            div(style = "flex: 1;"),
            div(style = "font-size: 11px; white-space: nowrap; flex-shrink: 0;",
              actionLink("sa_evidence_type", "Select All", style = "padding: 0;"),
              span(style = "color: #ccc; margin: 0 3px;", "|"),
              actionLink("da_evidence_type", "Deselect All", style = "padding: 0;")
            ),
            tags$a(href = "#", icon("search"), style = "color: #098ebb; font-size: 13px; text-decoration: none;",
              onclick = "$(this).hide().next('.filter-search-input').show().find('input').focus().on('blur',function(){$(this).val('').trigger('input');$(this).closest('.filter-search-input').hide().prev().show();}); return false;"),
            div(class = "filter-search-input", style = "display: none;",
              textInput("search_evidence_type", NULL, placeholder = "search...", width = "100%")
            )
          ),
          div(style = "max-height: 80px; overflow-y: auto; border: 1px solid #ddd; border-radius: 6px; padding: 4px 8px; background: #fff;",
            prettyCheckboxGroup("filter_evidence_type", NULL,
              choices = evidence_type_choices, selected = evidence_type_choices,
              shape = "curve", outline = TRUE, animation = "smooth", status = "success"
            )
          )
        ),
        div(class = "filter-card",
          div(style = "display: flex; align-items: center; gap: 6px;",
            tags$label("Quality Flag", style = "font-weight: 700; font-size: 13px; color: #333; margin-bottom: 0; white-space: nowrap;"),
            div(style = "flex: 1;"),
            div(style = "font-size: 11px; white-space: nowrap; flex-shrink: 0;",
              actionLink("sa_quality", "Select All", style = "padding: 0;"),
              span(style = "color: #ccc; margin: 0 3px;", "|"),
              actionLink("da_quality", "Deselect All", style = "padding: 0;")
            )
          ),
          div(style = "border: 1px solid #ddd; border-radius: 6px; padding: 12px 8px 4px; background: #fff;",
            prettyCheckboxGroup("filter_quality", NULL,
              choices = quality_flag_choices, selected = quality_flag_choices,
              shape = "curve", outline = TRUE, animation = "smooth", status = "success"
            )
          )
        ),
        
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
      div(style = "font-size: 12px; color: #888; margin: 2px 0 0 0;",
        icon("info-circle"), " Click on any ", strong("Factor"), " name to view detailed information"),
      div(style = "font-size: 11px; color: #999; margin: 0 0 8px 0;",
        icon("info-circle"), " Hover over ", strong("Supporting sentence"), " to read the full text"),
      hr(class = "section-divider"),
      div(class = "chart-card",
        withSpinner(DTOutput("data_table"), type = 4, color = "#098ebb")
      )
    )
  )
)
