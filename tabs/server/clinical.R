clinical_filtered <- reactive({
  df <- senres

  if (!is.null(input$clinical_cancer_type)) {
    df <- df %>% filter(`Cancer type` %in% input$clinical_cancer_type)
  }
  if (!is.null(input$clinical_factor_type)) {
    df <- df %>% filter(`Factor type` %in% input$clinical_factor_type)
  }
  df
})

observeEvent(input$clinical_reset, {
  updatePickerInput(session, "clinical_cancer_type", selected = cancer_types)
  updatePickerInput(session, "clinical_factor_type", selected = factor_types)
})

output$clinical_effect <- renderPlotly({
  req(clinical_filtered())
  proportion_pie(clinical_filtered(), "Direction", "Direction")
})

output$clinical_evidence_tumor <- renderPlotly({
  req(clinical_filtered())
  df <- clinical_filtered() %>%
    group_by(`Cancer type`, `Evidence type`) %>%
    summarise(n = n(), .groups = "drop") %>%
    na.omit()

  if (nrow(df) == 0) return(NULL)

  ev_levels <- sort(unique(df$`Evidence type`))
  n_colors <- length(ev_levels)
  bar_colors <- colorRampPalette(MODERN_COLORS)(n_colors)
  names(bar_colors) <- ev_levels

  p <- ggplot(df, aes(
    x = reorder(`Cancer type`, n, sum),
    y = n,
    fill = `Evidence type`,
    text = paste0(
      "Cancer: ", `Cancer type`, "<br>",
      "Evidence: ", `Evidence type`, "<br>",
      "Count: ", n
    )
  )) +
    geom_bar(stat = "identity", position = "fill", width = 0.7, color = "white", linewidth = 0.3) +
    scale_y_continuous(labels = percent_format(), expand = c(0, 0)) +
    scale_fill_manual(values = bar_colors) +
    coord_flip() +
    labs(
      x = "",
      y = "Proportion",
      fill = "Evidence Type"
    ) +
    theme_minimal(base_family = "Open Sans") +
    theme(
      plot.title = element_text(size = 14, face = "bold", color = "#333", hjust = 0, margin = margin(b = 10)),
      axis.text.y = element_text(size = 10, color = "#555"),
      axis.text.x = element_text(size = 9, color = "#555"),
      axis.title.x = element_text(size = 11, color = "#666", margin = margin(t = 8)),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_line(color = "#f0f0f0", linewidth = 0.5),
      legend.position = "bottom",
      legend.title = element_text(size = 10, color = "#555"),
      legend.text = element_text(size = 9, color = "#666"),
      plot.margin = margin(10, 10, 10, 10)
    )

  ggplotly(p, tooltip = "text") %>%
    layout(
      title = list(
        text = "<b>Evidence Type by Cancer Type</b>",
        font = list(size = 14, color = "#333", family = "Open Sans"),
        x = 0.05,
        xanchor = "left"
      ),
      margin = list(l = 10, r = 10, t = 40, b = 80),
      legend = list(
        orientation = "h",
        y = -0.3,
        font = list(size = 10, family = "Open Sans")
      ),
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)"
    )
})
