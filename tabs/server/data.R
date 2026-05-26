data_filtered <- reactive({
  df <- senres

  if (!is.null(input$filter_tumor_type)) {
    df <- df %>% filter(`Tumor Type` %in% input$filter_tumor_type)
  }
  if (!is.null(input$filter_tumor_subtype)) {
    df <- df %>% filter(`Tumor Subtype` %in% input$filter_tumor_subtype)
  }
  if (!is.null(input$filter_radiation_type)) {
    df <- df %>% filter(`Radiation Type` %in% input$filter_radiation_type)
  }
  if (!is.null(input$filter_factor_type)) {
    df <- df %>% filter(`Factor Type` %in% input$filter_factor_type)
  }
  if (!is.null(input$filter_evidence)) {
    df <- df %>% filter(`Evidence Level` %in% input$filter_evidence)
  }

  df
})

observeEvent(input$btn_reset, {
  updatePickerInput(session, "filter_tumor_type", selected = tumor_types)
  updatePickerInput(session, "filter_tumor_subtype", selected = tumor_subtypes)
  updatePickerInput(session, "filter_radiation_type", selected = radiation_types)
  updatePickerInput(session, "filter_factor_type", selected = factor_types)
  updatePickerInput(session, "filter_evidence", selected = evidence_levels)
})

output$chart_tumor_type <- renderPlotly({
  req(data_filtered())
  proportion_pie(data_filtered(), "Tumor Type", "Tumor Type")
})

output$chart_tumor_subtype <- renderPlotly({
  req(data_filtered())
  proportion_pie(data_filtered(), "Tumor Subtype", "Tumor Subtype")
})

output$chart_radiation_type <- renderPlotly({
  req(data_filtered())
  proportion_pie(data_filtered(), "Radiation Type", "Radiation Type")
})

output$chart_factor_type <- renderPlotly({
  req(data_filtered())
  proportion_pie(data_filtered(), "Factor Type", "Factor Type")
})

output$chart_evidence <- renderPlotly({
  req(data_filtered())
  proportion_pie(data_filtered(), "Evidence Level", "Evidence Level")
})

output$data_table <- renderDT({
  req(data_filtered())
  df <- data_filtered() %>%
    select(
      Title, `Tumor Type`, `Tumor Subtype`, `Radiation Type`,
      `Key Factor(s)`, `Effect Direction`, `Factor Type`,
      `Evidence Level`, `Year`, Journal, DOI
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
    class = "display nowrap"
  )
})
