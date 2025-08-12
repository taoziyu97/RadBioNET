##-- Atualizações dos filtros ----
##-- + Atualizações os anos ----
observeEvent(input$eleicoes_cargo_br,{
  cargo <- isolate(input$eleicoes_cargo_br)
  
  if(!is.null(cargo)){
    chaves_sub <- chaves
    # %>%
    #  filter(CODIGO_CARGO == cargo) 
    
    ##-- Setando o cargo default
    cancers <- sort(unique(senres$cancer_type))
    cancer_default <- input$eleicoes_ano_br
    if(!(cancer_default %in% cancers)){
      cancer_default <- cancers[1]
    }
    
    ## anos暂时保留 ----------------------------
    anos <- sort(unique(chaves_sub$ANO_ELEICAO))
    ## ----------------------------
    #ano_default <- input$eleicoes_ano_br
    
    #if(!(ano_default %in% anos)){
    #  ano_default <- anos[1]
    #}
    
    ##-- Atualizando os cargos ----
    updatePickerInput(session = session,
                      inputId = "eleicoes_ano_br",
                      label = "Cancer Type", 
                      choices = cancers, 
                      selected = cancer_default)
    
  }
  
}, priority = 1)

##-- + Atualizações dos turnos ----
observeEvent(c(input$eleicoes_ano_br, 
               input$eleicoes_cargo_br),{
                 
                 ano <- isolate(input$eleicoes_ano_br)
                 cargo <- isolate(input$eleicoes_cargo_br)
                 
                 if(!is.null(cargo)){
                   chaves_sub <- chaves
                   factorcalss_default <- "Gene"
                   #%>%
                   #  filter(ANO_ELEICAO == ano & CODIGO_CARGO == cargo)
                   
                   ##-- Setando o cargo default
                   # turnos <- unique(chaves_sub$NUM_TURNO)
                   # turno_default <- input$eleicoes_turno_br
                   
                   # if(!(turno_default %in% paste0(turnos, "º round")) | length(turnos) == 0){
                   #   turno_default <- "1º round"
                   # }
                   
                   # if(length(turnos) == 0){
                   #   turnos <- ""
                   # } else{
                   #   turnos <- paste0(turnos, "º round")
                   # }
                   
                   ##-- Atualizando os turnos ----
                   updatePickerInput(session = session,  # 修正拼写错误: sessio -> session
                                     inputId = "eleicoes_turno_br", 
                                     label = "Factor Class", 
                                     choices = factorcalss, 
                                     selected = factorcalss_default)
                 }
                 
               }, priority = 2)

##-- + Atualizações dos estados ----
observeEvent(c(input$eleicoes_ano_br, 
               input$eleicoes_cargo_br, 
               input$eleicoes_turno_br),{
                 
                 ano <- isolate(input$eleicoes_ano_br)
                 cargo <- isolate(input$eleicoes_cargo_br)
                 turno <- isolate(input$eleicoes_turno_br)
                 turno <- ifelse(turno != "1º round", "2", "1")
                 
                 if(!is.null(turno)){
                   chaves_sub <- chaves
                   # %>%
                    # filter(ANO_ELEICAO == ano & NUM_TURNO == turno)
                   ##-- Setando o estado default
                   estados <- levels(factor(x = sort(unique(chaves_sub$UF)),
                                             levels = sort(unique(chaves_sub$UF))))
                   estado_default <- input$eleicoes_estado_br
                   
                   if(!(estado_default %in% estados)){
                     estado_default <- "AC"
                   }
                   
                   ##-- Atualizando os partidos ----
                   updatePickerInput(session = session,
                                     inputId = "eleicoes_estado_br",
                                     label = "State", 
                                     choices = estados, 
                                     selected = estado_default)  
                 }
                 
               }, priority = 3)

##-- Reactive para os dados ----
dados_eleicao_geral_br <- reactive({
  ##-- + Inputs ----
  ano <- input$eleicoes_ano_br
  cargo <- input$eleicoes_cargo_br
  turno <- input$eleicoes_turno_br
  turno <- ifelse(turno != "1º round", "2", "1")
  
  ##-- + Selecionando os dados ----
  dados <- senres %>% filter(cancer_type == ano)
  # 筛选：dados_gerais %>% filter(ANO_ELEICAO == ano & CODIGO_CARGO == cargo & NUM_TURNO == turno)
  
  return(dados)
})

##-- Reactive para gerar as visualizações ----
graficos_eleicao_geral_br <- eventReactive(input$eleicoes_gerar_visualizacoes_br, {
  dados <- dados_eleicao_geral_br() # 获取筛选后的数据
  
  cod_uf <- input$eleicoes_estado_br
  if(cod_uf == "All states") cod_uf <- NULL # "全部州"转为NULL值
  
  graficos <- list() # 初始化图形列表
  
  # 准备地图数据：重命名行政区划数据框的列
  names(regUF)[c(1, 3)] <- c("UF", "REG")
  graficos[[1]] <- mapa_uf(data = dados, poly = regUF)  # 州级地图
  graficos[[2]] <- mapa_mun(data = dados, poly = regMun, uf = cod_uf)  # 市级地图
  # 创建一个柱状图
  ## 生成的图表对象存储在列表 graficos 的第三个位置 ([[3]])
  graficos[[3]] <- bar_plot(
    data = dados, 
    uf = cod_uf, 
    value_var = "QTDE_VOTOS_TOT", 
    group_var = "NOME_URNA_CANDIDATO")

  # 命名图形列表元素
  names(graficos) <- c("mapa_uf_br", "mapa_mun_br", "bar_plot_br")
  
  return(graficos)
})

##-- Mapa dos candidatos à presidência por estados ----
output$mapa_uf_geral_br <- renderLeaflet({
  graficos_eleicao_geral_br()$mapa_uf_br
})

##-- Mapa dos candidatos municipais ----
output$mapa_mun_geral_br <- renderLeaflet({
  graficos_eleicao_geral_br()$mapa_mun_br
})

##-- Gráfico de barras com o percentual de votos por candidato ----
output$barras_geral_br <- renderPlotly({
  graficos_eleicao_geral_br()$bar_plot_br
})

### 新增部分：数据框展示 ###

##-- Reactive para os dados filtrados por estado ----
dados_filtrados_br <- reactive({
  dados <- dados_eleicao_geral_br()
  cod_uf <- input$eleicoes_estado_br
  
  # 如果选择了具体州，则过滤数据
  if(!is.null(cod_uf) && cod_uf != "All states"){
    dados <- dados %>% filter(UF == cod_uf)
  }
  
  return(dados)
})

##-- Tabela de dados ----
output$tabela_dados_br <- renderDT({
  # 等待按钮点击
  input$eleicoes_gerar_visualizacoes_br
  
  # 获取数据
  dados <- dados_filtrados_br()
  
  # 创建数据表
  datatable(
    dados,
    extensions = c('Buttons', 'Scroller'),
    options = list(
      dom = 'Bfrtip',
      buttons = c('copy', 'csv', 'excel', 'print'),
      scrollX = TRUE,
      scrollY = "500px",
      scroller = TRUE,
      pageLength = 10,
      language = list(
        url = '//cdn.datatables.net/plug-ins/1.10.25/i18n/Portuguese-Brasil.json'
      )
    ),
    rownames = FALSE,
    class = 'display nowrap'
  )
})

##-- Resumo dos dados ----
output$resumo_dados_br <- renderPrint({
  # 等待按钮点击
  input$eleicoes_gerar_visualizacoes_br
  
  # 获取数据
  dados <- dados_filtrados_br()
  
  # 显示数据摘要
  cat("Resumo dos Dados Eleitorais\n")
  cat("===========================\n\n")
  cat("Total de Registros: ", nrow(dados), "\n")
  cat("Período Eleitoral: ", unique(dados$ANO_ELEICAO), "\n")
  cat("Cargo: ", unique(dados$DESCRICAO_CARGO), "\n\n")
  
  cat("Distribuição por Estado:\n")
  print(table(dados$SIGLA_UF))
  
  cat("\nTop 5 Candidatos por Votos:\n")
  top_candidatos <- dados %>%
    group_by(NOME_URNA_CANDIDATO) %>%
    summarise(Total_Votos = sum(QTDE_VOTOS_TOT, na.rm = TRUE)) %>%
    arrange(desc(Total_Votos)) %>%
    head(5)
  
  print(top_candidatos)
})