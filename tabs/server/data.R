# ---- Filter reactive ----

data_filtered <- reactive({
  df <- senres

  if (!is.null(input$filter_cancer_type)) {
    mask <- rep(FALSE, nrow(df))
    for (val in input$filter_cancer_type) {
      mask <- mask | grepl(val, df[["Cancer type"]], fixed = TRUE)
    }
    df <- df[mask, ]
  }
  if (!is.null(input$filter_particle_type)) {
    mask <- rep(FALSE, nrow(df))
    for (val in input$filter_particle_type) {
      mask <- mask | grepl(val, df[["Particle type"]], fixed = TRUE)
    }
    df <- df[mask, ]
  }
  if (!is.null(input$filter_factor_type)) {
    mask <- rep(FALSE, nrow(df))
    for (val in input$filter_factor_type) {
      mask <- mask | grepl(val, df[["Factor type"]], fixed = TRUE)
    }
    df <- df[mask, ]
  }
  if (!is.null(input$filter_direction)) {
    mask <- rep(FALSE, nrow(df))
    for (val in input$filter_direction) {
      mask <- mask | grepl(val, df[["Direction"]], fixed = TRUE)
    }
    df <- df[mask, ]
  }
  if (!is.null(input$filter_evidence_type)) {
    mask <- rep(FALSE, nrow(df))
    for (val in input$filter_evidence_type) {
      mask <- mask | grepl(val, df[["Evidence type"]], fixed = TRUE)
    }
    df <- df[mask, ]
  }
  if (!is.null(input$filter_quality)) {
    mask <- rep(FALSE, nrow(df))
    for (val in input$filter_quality) {
      mask <- mask | grepl(val, df[["Quality flag"]], fixed = TRUE)
    }
    df <- df[mask, ]
  }
  if (!is.null(input$filter_year)) {
    df <- df %>% filter(`Publication year` %in% input$filter_year)
  }

  df
})

observeEvent(input$btn_reset, {
  updatePickerInput(session, "filter_cancer_type", selected = cancer_type_choices)
  updatePickerInput(session, "filter_particle_type", selected = particle_type_choices)
  updatePickerInput(session, "filter_factor_type", selected = factor_type_choices)
  updatePickerInput(session, "filter_direction", selected = direction_choices)
  updatePickerInput(session, "filter_evidence_type", selected = evidence_type_choices)
  updatePickerInput(session, "filter_quality", selected = quality_flag_choices)
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
  url_factor <- URLencode(df[["Factor"]], reserved = TRUE)

  df <- df %>%
    mutate(
      Factor = sprintf(
        '<a href="?factor=%s" onclick="Shiny.setInputValue(\'open_factor\', \'%s\', {priority: \'event\'}); return false;" style="color: #098ebb; font-weight: 600; text-decoration: underline; text-decoration-style: dotted;">%s</a>',
        url_factor, safe_factor, htmlEscape(Factor)
      )
    ) %>%
    select(
      Factor, `Cancer type`, `Cancer subtype`,
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

observeEvent(input$open_factor, {
  req(input$open_factor)
  fname <- input$open_factor
  target_qs <- paste0("?factor=", URLencode(fname, reserved = TRUE))
  current_qs <- session$clientData$url_search
  if (is.null(current_qs) || current_qs != target_qs) {
    updateQueryString(target_qs, mode = "replace")
  }
  fd <- senres %>% filter(Factor == fname)
  if (nrow(fd) == 0) return()

  ftype <- unique(fd[["Factor type"]])[1]
  total_papers <- n_distinct(fd[["Title"]])
  n_cancer <- n_distinct(fd[["Cancer type"]], na.rm = TRUE)
  yr <- range(fd[["Publication year"]], na.rm = TRUE)
  n_ev <- n_distinct(fd[["Evidence type"]])

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

  subtypes <- fd %>%
    mutate(`Cancer subtype` = ifelse(is.na(`Cancer subtype`) | `Cancer subtype` == "", "(Unknown)", `Cancer subtype`)) %>%
    group_by(`Cancer subtype`) %>%
    summarise(n = n(), .groups = "drop") %>%
    arrange(desc(n))

  evidence_dist <- fd %>%
    group_by(`Evidence type`) %>%
    summarise(n = n(), .groups = "drop") %>%
    arrange(desc(n))


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
      margin = list(l = 10, r = 10, t = 5, b = 30),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )

  dir_plot <- plot_ly(dir_dist,
    labels = ~Direction, values = ~n, type = "pie", hole = 0.55,
    textinfo = "label+percent", textfont = list(size = 9),
    marker = list(colors = MODERN_COLORS),
    showlegend = FALSE,
    hovertemplate = "<b>%{label}</b>: %{value} records (%{percent})<extra></extra>"
  ) %>%
    layout(margin = list(t = 4, b = 4, l = 4, r = 4),
           paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)")

  evidence_plot <- plot_ly(evidence_dist,
    x = ~n, y = ~reorder(`Evidence type`, n),
    type = "bar", orientation = "h",
    marker = list(color = "#66b2b2", line = list(color = "#fff", width = 0.5)),
    hovertemplate = "<b>%{y}</b>: %{x} records<extra></extra>"
  ) %>%
    layout(
      xaxis = list(title = "Records", tickfont = list(size = 10)),
      yaxis = list(title = "", automargin = TRUE, tickfont = list(size = 10)),
      margin = list(l = 10, r = 10, t = 5, b = 30),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )


  output$factor_header <- renderUI({
    div(
      h3(style = "margin: 0; color: #098ebb; font-weight: 700; font-size: 22px; display: inline-block;",
        fname),
      span(style = "font-size: 12px; color: #fff; background-color: #098ebb; border-radius: 4px;
            padding: 3px 10px; margin-left: 12px; font-weight: 600; display: inline-block;
            vertical-align: middle;", ftype)
    )
  })

  output$factor_links <- renderUI({
    if (length(links) == 0) return(NULL)
    div(style = "margin: 18px 0 22px 0; text-align: center;",
      lapply(names(links), function(nm) {
        tags$a(href = links[[nm]], target = "_blank",
          class = "btn btn-primary btn-xs",
          style = "background-color: #098ebb; border: none; border-radius: 4px;
                   padding: 5px 14px; font-size: 12px; margin: 2px 4px;",
          icon("external-link-alt"), " ", nm)
      })
    )
  })

  output$factor_stat_papers <- renderText(total_papers)
  output$factor_stat_cancers <- renderText(n_cancer)
  output$factor_stat_years <- renderText(paste0(yr[1], "\U2013", yr[2]))
  output$factor_stat_evidence <- renderText(n_ev)

  output$factor_cancer_plot <- renderPlotly({
    cancer_plot
  })
  output$factor_dir_plot <- renderPlotly({
    dir_plot
  })
  output$factor_evidence_plot <- renderPlotly({
    evidence_plot
  })
  output$factor_top_subtypes <- renderUI({
    if (nrow(subtypes) == 0) return(div(class = "text-muted", "No data"))
    top <- head(subtypes, 3)
    tags$ul(style = "padding-left: 18px; margin: 0;",
      lapply(seq_len(nrow(top)), function(i) {
        tags$li(paste0(top[["Cancer subtype"]][i], ": ", top[["n"]][i]))
      })
    )
  })
  output$factor_papers <- renderDT({
    datatable(
      papers,
      options = list(
        pageLength = 10,
        lengthMenu = list(c(10, 25, 50), c("10", "25", "50")),
        dom = "tip",
        scrollX = TRUE
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        columns = names(papers),
        fontSize = "12px",
        fontFamily = "Open Sans"
      )
  })

  updateNavbarPage(session, "navbar", selected = "factor_detail")
})

observeEvent(input$factor_back_data, {
  updateQueryString("", mode = "replace")
  updateNavbarPage(session, "navbar", selected = "data")
})

observe({
  q <- parseQueryString(session$clientData$url_search)
  if (!is.null(q$factor) && nchar(q$factor) > 0) {
    updateNavbarPage(session, "navbar", selected = "factor_detail")
    session$sendInputMessage("open_factor", list(value = q$factor, priority = "event"))
  } else {
    updateNavbarPage(session, "navbar", selected = "data")
  }
})
