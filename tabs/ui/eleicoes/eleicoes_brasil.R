eleicoes_brasil <- tabPanel(title = "Sensitivity/Resistance Factors", 
                            value = "brasil",
                            br(), hr(),
                            ##-- Botões ----
                            column(width = 10,
                                   ##-- + Ano ----
                                   column(width = 2,
                                          pickerInput(inputId = "eleicoes_ano_br", 
                                                      label = "Cancer Type", 
                                                      choices = sort(cancers, decreasing = T), 
                                                      selected = "GBM", 
                                                      options = list(`live-search` = TRUE))
                                   ),
                                   ##-- + Cargo ----
                                   column(width = 2,
                                          pickerInput(inputId = "eleicoes_cargo_br", 
                                                      label = "Radiation Type", 
                                                      choices = sort(radiations, decreasing = T), 
                                                      selected = 1,
                                                      options = list(`live-search` = TRUE))
                                   ),
                                   ##-- + Turno ----
                                   column(width = 2,
                                          pickerInput(inputId = "eleicoes_turno_br", 
                                                      label = "Factor Class", 
                                                      choices = sort(factorcalss, decreasing = T), 
                                                      selected = "Gene",
                                                      options = list(`live-search` = TRUE))
                                   ),
                                   ##-- + Estado ----
                                   column(width = 2,
                                          pickerInput(inputId = "eleicoes_estado_br", 
                                                      label = "State", 
                                                      choices = levels(factor(x = sort(unique(chaves$UF)),
                                                                              levels = sort(unique(chaves$UF)))), 
                                                      selected = "AC",
                                                      options = list(`live-search` = TRUE,
                                                                     `none-selected-text` = "None selected"))
                                   )
                            ), 
                            ##-- Visualizar ----
                            column(width = 2, style = "padding-top: 50px;",
                                   actionBttn(inputId = "eleicoes_gerar_visualizacoes_br", 
                                              label = "Select", 
                                              style = "fill", 
                                              color = "success", 
                                              icon = icon("check"), size = "sm") 
                            ),
                            conditionalPanel(condition = "input.eleicoes_gerar_visualizacoes_br < 1",
                                             column(width = 12,
                                                    br(), 
                                                    wellPanel(
                                                      HTML("<h1>Sensitivity/Resistance factor<h1>"),
                                                      HTML("<h4>In this tab, the user can explore the sensitivity factor and resistance factor.
                                                           .<h4>")
                                                    )
                                             )
                            ),
                            ##-- Outputs ----
                            column(width = 12,
                                   ##-- + Mapa do Brasil ----
                                   column(width = 4,
                                          conditionalPanel(condition = "input.eleicoes_gerar_visualizacoes_br > 0",
                                                           HTML("<center><h1>Number of patients</h1></center>"),
                                                           br(),
                                                           withSpinner(leafletOutput("mapa_uf_geral_br"), type = 6)
                                          )
                                   ),
                                   ##-- + Mapa dos municípios ----
                                   column(width = 4,
                                          conditionalPanel(condition = "input.eleicoes_gerar_visualizacoes_br > 0",
                                                           HTML("<center><h1>Type of radiotherapy</h1></center>"),
                                                           br(),
                                                           withSpinner(leafletOutput("mapa_mun_geral_br"), type = 6)
                                                           
                                          )
                                   ),
                                   ##-- + Gráfico de barras ----
                                   column(width = 4,
                                          conditionalPanel(condition = "input.eleicoes_gerar_visualizacoes_br > 0",
                                                           HTML("<center><h1>CANCER TYPES (%)</h1></center>"),
                                                           br(),
                                                           withSpinner(plotlyOutput("barras_geral_br"), type = 6)
                                                           
                                          )
                                   )
                            ),
       ##-- 新增：数据表展示 ----
       column(width = 12,
              conditionalPanel(condition = "input.eleicoes_gerar_visualizacoes_br > 0",
                               br(), br(),
                               HTML("<center><h1>Database</h1></center>"),
                               withSpinner(DTOutput("tabela_dados_br"), type = 6),
                               verbatimTextOutput("resumo_dados_br")
              )
       )
)