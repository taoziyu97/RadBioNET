observeEvent(input$navbar, {
  if (input$navbar == "home") {
    sendSweetAlert(
      session = session,
      title = "Welcome to RadBioNet",
      text = HTML("
        <h3><b>Radiation Biology Database</b></h3>
        <br>
        This database compiles factors associated with radiation sensitivity and resistance
        in cancer, supporting precision radiotherapy research.
      "),
      type = "info",
      html = TRUE,
      closeOnClickOutside = FALSE
    )
  }
})

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
