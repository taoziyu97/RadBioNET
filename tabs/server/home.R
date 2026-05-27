observeEvent(input$analise_geral, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "data")
})
observeEvent(input$analise_partidos, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "clinical")
})
observeEvent(input$analise_candidatos, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "chat_radbio")
})
observeEvent(input$sobre, {
  updateTabsetPanel(session = session, inputId = "navbar", selected = "about")
})

output$home_chart_tumor_type <- renderPlotly({
  proportion_pie(senres, "Cancer type", "Cancer Type")
})

output$home_chart_radiation_type <- renderPlotly({
  proportion_pie(senres, "Radiation type", "Radiation Type")
})

output$home_chart_factor_type <- renderPlotly({
  proportion_pie(senres, "Factor type", "Factor Type")
})

output$home_chart_evidence <- renderPlotly({
  proportion_pie(senres, "Evidence type", "Evidence Type")
})
