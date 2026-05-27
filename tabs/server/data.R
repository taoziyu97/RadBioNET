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

output$data_table <- renderDT({
  req(data_filtered())

  df <- data_filtered() %>%
    select(
      Factor, `Cancer type`, `Cancer subtype`, `Radiation type`,
      Direction, `Factor type`, `Evidence type`, `Quality flag`,
      `Biological mechanism`, Journal, `Publication year`,
      Title, DOI
    )

  datatable(
    df,
    extensions = c("Buttons", "Scroller"),
    options = list(
      dom = "Bfrtip",
      buttons = c("copy", "csv", "excel", "print"),
      scrollX = TRUE,
      scrollY = "400px",
      scroller = TRUE,
      pageLength = 10,
      language = list(url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/English.json")
    ),
    rownames = FALSE,
    class = "display nowrap cell-border stripe",
    filter = "top"
  ) %>%
    formatStyle(
      columns = names(df),
      fontSize = "12px",
      fontFamily = "Open Sans"
    )
})
