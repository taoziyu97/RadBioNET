partido_geral <- tabPanel(title = "Biological resource", 
                          value = "partidos_geral",
                          br(), hr(),
                          column(width = 10,
                                 column(width = 2,
                                        pickerInput(inputId = "partido_geral_ano", 
                                                    label = "test", 
                                                    choices = anos, 
                                                    selected = "GBM", 
                                                    options = list(`live-search` = TRUE))
                                 ),
                                 column(width = 2,
                                        pickerInput(inputId = "partido_geral_cargo", 
                                                    label = "Position", 
                                                    choices = cargos, 
                                                    selected = "GOVERNOR", 
                                                    options = list(`live-search` = TRUE))
                                 )
                          ),
                          column(width = 2, style = "padding-top: 50px;",
                                 actionBttn(inputId = "partidos_gerar_visualizacoes1", 
                                            label = "Select", 
                                            style = "fill", 
                                            color = "success", 
                                            icon = icon("check"), size = "sm") 
                          ),
                          conditionalPanel(condition = "input.partidos_gerar_visualizacoes1 < 1",
                                           column(width = 12,
                                                  br(), 
                                                  wellPanel(
                                                    HTML("<h1>Biology resource<h1>"),
                                                    HTML("<h4>
                                                         This tab provides biology resource 
                                                         <h4>")
                                                  )
                                           )
                          ),
                          column(width = 12,
                                 column(width = 6,
                                        conditionalPanel(condition = "input.partidos_gerar_visualizacoes1 > 0",
                                                         br(), hr(), br(),
                                                         HTML("<center><h1>COALITIONS HEATMAP</h1></center>"),
                                                         column(width = 12,
                                                                withSpinner(plotlyOutput("heatmap_coligacoes"), 6)
                                                         )           
                                        )
                                 ),
                                 column(width = 6,
                                        conditionalPanel(condition = "input.partidos_gerar_visualizacoes1 > 0 & input.partido_geral_cargo == 11",
                                                         br(), hr(), br(),
                                                         HTML("<center><h1>WINNERS PARTIES</h1></center>"),
                                                         column(width = 12,
                                                                withSpinner(leafletOutput("mapa_partidos_cid"), type = 6)
                                                         )           
                                        )
                                 )
                          )
)