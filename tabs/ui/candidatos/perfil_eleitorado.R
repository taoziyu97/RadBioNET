perfil_eleitorado <- tabPanel(title = "Chat-radbio -introduction", 
                              value = "candidatos_perfil_eleitorado",
                              br(), hr(),
                              column(width = 10,
                                     column(width = 2,
                                            pickerInput(inputId = "perfil_candidato_voronoi_ano", 
                                                        label = "test", 
                                                        choices = 2014,
                                                        selected = 2014)
                                     ),
                                     column(width = 2,
                                            pickerInput(inputId = "perfil_candidato_voronoi_cargo", 
                                                        label = "Position", 
                                                        choices = "PRESIDENT",
                                                        selected = "PRESIDENT")
                                     ),
                                     column(width = 2,
                                            pickerInput(inputId = "perfil_candidato_voronoi_turno", 
                                                        label = "Factor", 
                                                        choices = c("1º round", "2º round"), 
                                                        selected = "1º",
                                                        options = list(`live-search` = TRUE))
                                     ),
                                     column(width = 2,
                                            pickerInput(inputId = "perfil_candidato_voronoi_partido", 
                                                        label = "Party", 
                                                        choices = levels(factor(x = partidos,
                                                                                levels = partidos)), 
                                                        selected = "PT",
                                                        options = list(`live-search` = TRUE,
                                                                       `none-selected-text` = "None selected"))
                                     ),
                                     column(width = 2,
                                            pickerInput(inputId = "perfil_candidato_voronoi_estado", 
                                                        label = "State", 
                                                        choices = "SP", 
                                                        selected = "SP",
                                                        options = list(`live-search` = TRUE,
                                                                       `none-selected-text` = "None selected"))
                                     ),
                                     column(width = 2,
                                            pickerInput(inputId = "perfil_candidato_voronoi_municipio", 
                                                        label = "City", 
                                                        choices = municipios, 
                                                        selected = "3550308",
                                                        options = list(`live-search` = TRUE,
                                                                       `none-selected-text` = "None selected"))
                                     )
                              ),
                              column(width = 2, style = "padding-top: 50px;",
                                     actionBttn(inputId = "perfil_candidato_voronoi_gerar_visualizacoes", 
                                                label = "Select", 
                                                style = "fill", 
                                                color = "success", 
                                                icon = icon("check"), size = "sm"),
                                     HTML("&nbsp"),
                                     actionBttn(inputId = "perfil_candidato_voronoi_metodologia", 
                                                label = "Methodology", 
                                                style = "fill", 
                                                color = "danger", 
                                                icon = icon("book"), size = "sm")
                              ),
                              conditionalPanel(condition = "input.perfil_candidato_voronoi_gerar_visualizacoes < 1",
                                               column(width = 12,
                                                      br(), 
                                                      wellPanel(
                                                        HTML("<h1>生物放疗数据大模型（Chat-Radbio）介绍<h1>"),
                                                        HTML("<h4>
                                                              定位：专为放疗生物学研究设计的开源多模态大模型，旨在整合临床数据、多组学信息与AI算法，推动放疗从“物理精准”迈向“生物精准”。
                                                             <h4>")
                                                      )
                                               )
                              ),
                              column(width = 12,
                                     conditionalPanel(condition = "input.perfil_candidato_voronoi_gerar_visualizacoes > 0",
                                                      column(width = 6,
                                                             HTML("<center><h1>VOTES BY ELECTORAL SECTIONS</h1></center>")
                                                      ),
                                                      column(width = 6,
                                                             HTML("<center><h1>SOCIO-DEMOGRAPHIC VARIABLES</h1></center>"),
                                                             HTML("<center>"),
                                                             pickerInput(inputId = "perfil_candidato_voronoi_variavel", 
                                                                         label = "Variável", 
                                                                         choices = c("Income", "Income (categories)",
                                                                                     "% white", "% not white",
                                                                                     "% illiteracy",
                                                                                     "% women", "% men"),
                                                                         selected = "Income"),
                                                             HTML("</center>")
                                                      ),
                                                      column(width = 12,
                                                             withSpinner(uiOutput("mapa_voronoi", height = "500px"), type = 6)
                                                      )
                                     )
                              )
)