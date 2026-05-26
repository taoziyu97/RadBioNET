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
