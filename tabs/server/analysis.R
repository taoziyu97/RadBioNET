# Reactive data loading
timeline_data <- reactive({
  analysis_data$timeline
})

factor_trends_data <- reactive({
  analysis_data$factor_trends
})

modality_data <- reactive({
  analysis_data$modality
})

device_data <- reactive({
  analysis_data$device
})

dose_model_data <- reactive({
  analysis_data$dose_model
})

dose_particle_data <- reactive({
  analysis_data$dose_particle
})

nodes_data <- reactive({
  analysis_data$nodes
})

edges_data <- reactive({
  analysis_data$edges
})

triples_data <- reactive({
  analysis_data$triples
})

entities_data <- reactive({
  analysis_data$entities
})

# Factor choices for picker
factor_choices <- reactive({
  nd <- nodes_data()
  nd <- nd[order(nd$papers, decreasing = TRUE), ]
  nd$factor
})

observe({
  fc <- factor_choices()
  updatePickerInput(session, "analysis_factors", choices = fc, selected = fc[1:min(10, length(fc))])
})

# Timeline chart
output$analysis_timeline <- renderPlotly({
  req(input$navbar == "analysis")
  req(input$analysis_factors)
  td <- timeline_data()
  td <- td[td$Factor %in% input$analysis_factors, ]
  if (nrow(td) == 0) return(NULL)

  p <- plot_ly(td, x = ~Year, y = ~papers, color = ~Factor,
    type = "scatter", mode = "lines+markers",
    line = list(width = 2), marker = list(size = 6),
    hovertemplate = "<b>%{fullData.name}</b><br>Year: %{x}<br>Papers: %{y}<extra></extra>"
  ) %>%
    layout(
      xaxis = list(title = "Year", tickfont = list(size = 10)),
      yaxis = list(title = "Papers", tickfont = list(size = 10)),
      hovermode = "x unified",
      margin = list(l = 10, r = 10, t = 5, b = 40),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )
  p
})

# Trends table
output$analysis_trends_table <- renderDT({
  req(input$navbar == "analysis")
  ft <- factor_trends_data()
  ft <- ft[, c("Factor", "Total_papers", "Total_strong", "Trend_tag",
               "Trend_slope_2010_26", "Trend_p_value", "Peak_year", "Peak_year_count")]
  names(ft) <- c("Factor", "Papers", "Strong Ev.", "Trend", "Slope", "P-value", "Peak Year", "Peak Count")
  ft$Slope <- round(ft$Slope, 2)
  ft$`P-value` <- round(ft$`P-value`, 4)

  datatable(ft,
    options = list(
      dom = "Bfrtlip",
      pageLength = 10,
      scrollX = TRUE,
      scrollY = "400px",
      buttons = c("copy", "csv", "excel")
    ),
    extensions = c("Buttons"),
    rownames = FALSE,
    class = "display nowrap cell-border stripe"
  ) %>%
    formatStyle(columns = names(ft), fontSize = "12px", fontFamily = "Open Sans")
})

# Modality bar chart
output$analysis_modality <- renderPlotly({
  req(input$navbar == "analysis")
  md <- modality_data()
  plot_ly(md, x = ~reorder(Modality, Papers), y = ~Papers,
    type = "bar", orientation = "v",
    marker = list(color = MODERN_COLORS[1], line = list(color = "#fff", width = 0.5)),
    hovertemplate = "<b>%{x}</b>: %{y} papers<extra></extra>"
  ) %>%
    layout(
      xaxis = list(title = "", tickfont = list(size = 9), tickangle = -45),
      yaxis = list(title = "Papers", tickfont = list(size = 10)),
      margin = list(l = 10, r = 10, t = 5, b = 80),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )
})

# Device bar chart
output$analysis_device <- renderPlotly({
  req(input$navbar == "analysis")
  dd <- device_data()
  names(dd)[1] <- "Device"
  plot_ly(dd, x = ~reorder(Device, Papers), y = ~Papers,
    type = "bar", orientation = "v",
    marker = list(color = MODERN_COLORS[2], line = list(color = "#fff", width = 0.5)),
    hovertemplate = "<b>%{x}</b>: %{y} papers<extra></extra>"
  ) %>%
    layout(
      xaxis = list(title = "", tickfont = list(size = 9), tickangle = -45),
      yaxis = list(title = "Papers", tickfont = list(size = 10)),
      margin = list(l = 10, r = 10, t = 5, b = 80),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )
})

# Dose by model
output$analysis_dose_model <- renderPlotly({
  req(input$navbar == "analysis")
  dm <- dose_model_data()
  dm <- dm[!is.na(dm$`Median.single.dose..Gy.`), ]

  plot_ly(dm,
    x = ~reorder(Model, `Median.single.dose..Gy.`),
    y = ~`Median.single.dose..Gy.`,
    type = "bar",
    marker = list(color = MODERN_COLORS[3]),
    error_y = list(
      type = "data",
      symmetric = FALSE,
      array = ~(`Q3.single.dose..Gy.` - `Median.single.dose..Gy.`),
      arrayminus = ~(`Median.single.dose..Gy.` - `Q1.single.dose..Gy.`)
    ),
    hovertemplate = "<b>%{x}</b><br>Median: %{y} Gy<br>Q1-Q3: %{customdata}<extra></extra>",
    customdata = ~paste0(Q1.single.dose..Gy., " - ", Q3.single.dose..Gy., " Gy")
  ) %>%
    layout(
      xaxis = list(title = "", tickfont = list(size = 10), tickangle = -30),
      yaxis = list(title = "Median Single Dose (Gy)", tickfont = list(size = 10)),
      margin = list(l = 10, r = 10, t = 5, b = 60),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )
})

# Dose by particle
output$analysis_dose_particle <- renderPlotly({
  req(input$navbar == "analysis")
  dp <- dose_particle_data()
  dp <- dp[!is.na(dp$Median..Gy.), ]

  plot_ly(dp,
    x = ~reorder(Particle, Median..Gy.),
    y = ~Median..Gy.,
    type = "bar",
    marker = list(color = MODERN_COLORS[4]),
    error_y = list(
      type = "data",
      symmetric = FALSE,
      array = ~(Q3..Gy. - Median..Gy.),
      arrayminus = ~(Median..Gy. - Q1..Gy.)
    ),
    hovertemplate = "<b>%{x}</b><br>Median: %{y} Gy<br>Q1-Q3: %{customdata}<extra></extra>",
    customdata = ~paste0(Q1..Gy., " - ", Q3..Gy., " Gy")
  ) %>%
    layout(
      xaxis = list(title = "", tickfont = list(size = 10)),
      yaxis = list(title = "Median Dose (Gy)", tickfont = list(size = 10)),
      margin = list(l = 10, r = 10, t = 5, b = 40),
      paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)"
    )
})

# Knowledge graph
output$analysis_knowledge_graph <- renderVisNetwork({
  req(input$navbar == "analysis")
  nd <- nodes_data()
  ed <- edges_data()

  nodes <- data.frame(
    id = nd$factor,
    label = nd$factor,
    value = sqrt(nd$papers) / 2,
    group = nd$community,
    title = paste0("<b>", nd$factor, "</b><br>Papers: ", nd$papers, "<br>Category: ", nd$category),
    shape = "dot"
  )

  edges <- data.frame(
    from = ed$source,
    to = ed$target,
    value = ed$weight / max(ed$weight) * 5,
    title = paste0("Co-occurrence: ", ed$weight, "<br>Jaccard: ", round(ed$jaccard, 3))
  )

  visNetwork(nodes, edges) %>%
    visOptions(
      highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE),
      nodesIdSelection = TRUE
    ) %>%
    visPhysics(
      stabilization = TRUE,
      solver = "forceAtlas2Based"
    ) %>%
    visEdges(
      smooth = TRUE,
      color = list(color = "#ccc", highlight = "#098ebb")
    ) %>%
    visLayout(randomSeed = 42)
})
