clinical_filtered <- reactive({
  df <- senres

  if (!is.null(input$clinical_tumor_type)) {
    df <- df %>% filter(`Tumor Type` %in% input$clinical_tumor_type)
  }
  if (!is.null(input$clinical_factor_type)) {
    df <- df %>% filter(`Factor Type` %in% input$clinical_factor_type)
  }
  df
})

observeEvent(input$clinical_reset, {
  updatePickerInput(session, "clinical_tumor_type", selected = tumor_types)
  updatePickerInput(session, "clinical_factor_type", selected = factor_types)
})

output$clinical_effect <- renderPlotly({
  req(clinical_filtered())
  proportion_pie(clinical_filtered(), "Effect Direction", "Effect Direction")
})

output$clinical_evidence_tumor <- renderPlotly({
  req(clinical_filtered())
  df <- clinical_filtered() %>%
    group_by(`Tumor Type`, `Evidence Level`) %>%
    summarise(n = n(), .groups = "drop") %>%
    na.omit()

  if (nrow(df) == 0) return(NULL)

  p <- ggplot(df, aes(
    x = `Tumor Type`,
    y = n,
    fill = `Evidence Level`
  )) +
    geom_bar(stat = "identity", position = "fill", width = 0.7) +
    scale_y_continuous(labels = percent_format()) +
    scale_fill_brewer(palette = "Set2") +
    theme_classic() +
    labs(x = "", y = "Proportion", fill = "Evidence Level") +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
      legend.position = "bottom"
    )

  ggplotly(p, tooltip = c("x", "fill", "y")) %>%
    layout(margin = list(b = 80))
})
