# ---- Filter reactive ----

data_filtered <- reactive({
  df <- senres

  if (!is.null(input$filter_cancer_type)) {
    df <- df %>% filter(`Cancer type` %in% input$filter_cancer_type)
  }
  if (!is.null(input$filter_radiation_type)) {
    df <- df %>% filter(`Radiation type` %in% input$filter_radiation_type)
  }
  if (!is.null(input$filter_factor_type)) {
    df <- df %>% filter(`Factor type` %in% input$filter_factor_type)
  }
  if (!is.null(input$filter_direction)) {
    df <- df %>% filter(Direction %in% input$filter_direction)
  }
  if (!is.null(input$filter_evidence_type)) {
    df <- df %>% filter(`Evidence type` %in% input$filter_evidence_type)
  }
  if (!is.null(input$filter_quality)) {
    df <- df %>% filter(`Quality flag` %in% input$filter_quality)
  }
  if (!is.null(input$filter_year)) {
    df <- df %>% filter(`Publication year` %in% input$filter_year)
  }

  df
})

observeEvent(input$btn_reset, {
  updatePickerInput(session, "filter_cancer_type", selected = cancer_types)
  updatePickerInput(session, "filter_radiation_type", selected = radiation_types)
  updatePickerInput(session, "filter_factor_type", selected = factor_types)
  updatePickerInput(session, "filter_direction", selected = directions)
  updatePickerInput(session, "filter_evidence_type", selected = evidence_types)
  updatePickerInput(session, "filter_quality", selected = quality_flags)
  updatePickerInput(session, "filter_year", selected = years)
})

# ---- Statistics cards ----

output$stat_total <- renderText({
  nrow(data_filtered())
})

output$stat_factors <- renderText({
  length(unique(data_filtered()[["Factor"]]))
})

output$stat_cancers <- renderText({
  length(unique(data_filtered()[["Cancer type"]]))
})

output$stat_years <- renderText({
  r <- range(data_filtered()[["Publication year"]], na.rm = TRUE)
  paste(r[1], "–", r[2])
})

# ---- Data table with clickable Factor column ----

output$data_table <- renderDT({
  req(data_filtered())

  df <- data_filtered()
  safe_factor <- vapply(df[["Factor"]], function(f) {
    gsub("'", "\\\\u0027", f)
  }, character(1), USE.NAMES = FALSE)

  df <- df %>%
    mutate(
      Factor = sprintf(
        '<a href="#" onclick="Shiny.setInputValue(\'show_factor\', \'%s\', {priority: \'event\'}); return false;">%s</a>',
        safe_factor, htmlEscape(Factor)
      )
    ) %>%
    select(
      Factor, `Cancer type`, `Cancer subtype`, `Radiation type`,
      Direction, `Factor type`, `Evidence type`, `Quality flag`,
      `Biological mechanism`, Journal, `Publication year`,
      Title, DOI
    )

  datatable(
    df,
    extensions = c("Buttons"),
    escape = FALSE,
    options = list(
      dom = "Bfrtlip",
      buttons = c("copy", "csv", "excel", "print"),
      scrollX = TRUE,
      scrollY = "400px",
      pageLength = 10,
      lengthMenu = list(c(10, 25, 50, 100, -1), c("10", "25", "50", "100", "All")),
      language = list(
        url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/English.json",
        lengthMenu = "Show _MENU_ entries"
      )
    ),
    rownames = FALSE,
    class = "display nowrap cell-border stripe"
  ) %>%
    formatStyle(
      columns = names(df),
      fontSize = "12px",
      fontFamily = "Open Sans"
    )
})

# ---- Factor detail modal ----

observeEvent(input$show_factor, {
  req(input$show_factor)
  fname <- input$show_factor
  fd <- senres %>% filter(Factor == fname)
  if (nrow(fd) == 0) return()

  ftype <- unique(fd[["Factor type"]])[1]
  total_papers <- n_distinct(fd[["Title"]])
  n_cancer <- n_distinct(fd[["Cancer type"]], na.rm = TRUE)
  yr <- range(fd[["Publication year"]], na.rm = TRUE)
  n_ev <- n_distinct(fd[["Evidence type"]])
  source_batches <- sort(unique(fd[["Source batch"]]))

  cancer_dist <- fd %>%
    group_by(`Cancer type`) %>%
    summarise(n = n(), .groups = "drop") %>%
    na.omit() %>%
    arrange(desc(n))

  dir_dist <- fd %>%
    group_by(Direction) %>%
    summarise(n = n(), .groups = "drop") %>%
    arrange(desc(n))

  papers <- fd %>%
    select(Title, Journal, `Publication year`, DOI, Direction, `Quality flag`) %>%
    distinct() %>%
    arrange(desc(`Publication year`))

  links <- get_factor_links(fname, ftype)

  cancer_plot <- plot_ly(cancer_dist,
    x = ~n, y = ~reorder(`Cancer type`, n),
    type = "bar", orientation = "h",
    marker = list(color = "#098ebb", line = list(color = "#fff", width = 0.5)),
    hovertemplate = "<b>%{y}</b>: %{x} records<extra></extra>"
  ) %>%
    layout(
      xaxis = list(title = "Records", tickfont = list(size = 10)),
      yaxis = list(title = "", automargin = TRUE, tickfont = list(size = 10)),
      margin = list(l = 10, r = 10, t = 5, b = 40),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )

  dir_plot <- plot_ly(dir_dist,
    labels = ~Direction, values = ~n, type = "pie", hole = 0.4,
    textinfo = "label+percent", textfont = list(size = 10),
    marker = list(colors = MODERN_COLORS),
    showlegend = FALSE,
    hovertemplate = "<b>%{label}</b>: %{value} records (%{percent})<extra></extra>"
  ) %>%
    layout(margin = list(t = 5, b = 5, l = 5, r = 5),
           paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)")

  showModal(modalDialog(
    title = div(style = "border-bottom: 2px solid #098ebb; padding-bottom: 10px;",
      div(style = "display: flex; justify-content: space-between; align-items: center;",
        div(
          h3(style = "margin: 0; color: #098ebb; font-weight: 700; font-size: 20px; display: inline;", fname),
          span(style = "font-size: 13px; color: #888; margin-left: 10px;", ftype)
        )
      )
    ),
    size = "l", easyClose = TRUE,
    footer = modalButton("Close"),

    tags$head(tags$style(HTML(".modal-dialog { width: 90% !important; max-width: 1100px; } .factor-link-btn { margin: 2px 4px; }"))),

    # External links
    if (length(links) > 0) {
      div(style = "margin: 12px 0;",
        lapply(names(links), function(nm) {
          tags$a(href = links[[nm]], target = "_blank",
            class = "btn btn-primary btn-xs factor-link-btn",
            style = "background-color: #098ebb; border: none; border-radius: 4px;",
            icon("external-link-alt"), " ", nm)
        })
      )
    },

    # Stats cards
    fluidRow(
      column(3, div(class = "stat-card", div(class = "stat-value", total_papers), div(class = "stat-label", "Papers"))),
      column(3, div(class = "stat-card", div(class = "stat-value", n_cancer), div(class = "stat-label", "Cancer Types"))),
      column(3, div(class = "stat-card", div(class = "stat-value", paste0(yr[1], "–", yr[2])), div(class = "stat-label", "Year Range"))),
      column(3, div(class = "stat-card", div(class = "stat-value", n_ev), div(class = "stat-label", "Evidence Types")))
    ),

    br(),

    # Charts row
    fluidRow(
      column(width = 7,
        h5(style = "font-weight: 600; color: #333; margin-bottom: 5px;", "Cancer Type Distribution"),
        div(style = "height: 280px;", as_widget(cancer_plot))
      ),
      column(width = 5,
        h5(style = "font-weight: 600; color: #333; margin-bottom: 5px;", "Direction Distribution"),
        div(style = "height: 280px;", as_widget(dir_plot))
      )
    ),

    br(),

    # Source batch
    div(style = "font-size: 12px; color: #999; margin-bottom: 10px;",
      "Source: ", paste(source_batches, collapse = ", ")
    ),

    # Papers table
    h5(style = "font-weight: 600; color: #333; margin-bottom: 5px;",
      "Related Papers (", nrow(papers), ")"),
    div(style = "max-height: 300px; overflow-y: auto; border: 1px solid #e8e8e8; border-radius: 6px; padding: 5px;",
      tableOutput("factor_papers")
    ),

    br()
  ))

  output$factor_papers <- renderTable({
    papers
  }, striped = TRUE, bordered = TRUE, hover = TRUE, spacing = "s", width = "100%",
     digits = 0)
})
