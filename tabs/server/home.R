observeEvent(input$navbar,{
  if(input$navbar == "home"){
    sendSweetAlert(
      session = session,
      title = "Welcome to our database",
      text = HTML("Please click here and go first to: <br> 
                  <h3><b><a id='link_info' href='#' class='action-button'><i class='fas fa-arrow-right'></i> Voter profile <i class='fas fa-arrow-left'></i></a></b></h3> 
                  <br> This is our database, which utilizes a large amount of public data. Through this database, we have compiled all biological content related to radiation therapy."),
      type = "info", 
      html = TRUE,
      closeOnClickOutside = FALSE
    )
  }
})

##-- + Atualizando abas conforme os cliques ----
observeEvent(input$analise_geral,{
  updateTabsetPanel(session = session, inputId = "navbar", selected = "eleicoes")
})
observeEvent(input$analise_partidos,{
  updateTabsetPanel(session = session, inputId = "navbar", selected = "partidos")
})
observeEvent(input$analise_candidatos,{
  updateTabsetPanel(session = session, inputId = "navbar", selected = "candidatos")
})
observeEvent(input$sobre,{
  updateTabsetPanel(session = session, inputId = "navbar", selected = "sobre")
})
observeEvent(input$link_info,{
  updateTabsetPanel(session = session, inputId = "navbar", selected = "candidatos_perfil_eleitorado")
  closeSweetAlert(session = session)
})