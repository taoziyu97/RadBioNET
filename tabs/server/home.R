observeEvent(input$analise_geral, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "data")
})
observeEvent(input$analise_partidos, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "analysis")
})
observeEvent(input$analise_candidatos, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "chat_radbio")
})
observeEvent(input$sobre, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "about")
})

output$home_stat_total <- renderText({
  nrow(senres)
})

output$home_stat_years <- renderText({
  r <- range(senres[["Publication year"]], na.rm = TRUE)
  paste0(r[1], " \U2013 ", r[2])
})

output$home_stat_particles <- renderText({
  n_distinct(senres[["Particle type"]][!senres[["Particle type"]] %in% c("(none)", NA, "(Unknown)")])
})

output$home_chart_tumor_type <- renderPlotly({
  proportion_pie(senres, "Cancer type", "Cancer Type")
})

output$home_chart_radiation_type <- renderPlotly({
  proportion_pie(senres, "Particle type", "Particle Type")
})

output$home_chart_factor_type <- renderPlotly({
  proportion_pie(senres, "Factor type", "Factor Type")
})

output$home_chart_evidence <- renderPlotly({
  proportion_pie(senres, "Evidence type", "Evidence Type")
})
