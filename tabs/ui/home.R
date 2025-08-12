home <- tabPanel(title = "Home", 
                 value = "home",
                 hr(),
                 br(), br(),
                 HTML("<h1><center>WELCOME TO <b>RadBioNet</b> ...</center></h1>"),
                 br(), br(), br(), br(),
                 column(width = 3, align = "center",
                        tab_voronoys(texto = "Multi-omics Data Integration Module", cor = cores[1], icon = "brasil.png", id = "analise_geral")
                        ),
                 column(width = 3, align = "center",
                        tab_voronoys(texto = "Clinical Samples and Biological Resources", cor = cores[2], icon = "flag.png", id = "analise_partidos")
                 ),
                 column(width = 3, align = "center",
                        tab_voronoys(texto = "ChatRaBio and Prognostic Model Module", cor = cores[3], icon = "person.png", id = "analise_candidatos")
                 ),
                 column(width = 3, align = "center",
                        tab_voronoys(texto = "About us", cor = cores[4], icon = "sobre.png", id = "sobre")
                 ),
                 column(width = 12,
                        br(), br(), br(), br(),
                        wellPanel(
                          HTML("<h1><b>RadBioNet</b></h1>"),
                          HTML('<h4><b>RadBioNet</b> (Radiation Biology Network) is a resource developed by the Department of Radiation Oncology at <span style="color: #19509A; font-weight: bold;">Ruijin Hospital</span>, Shanghai JiaoTong University, and is closely associated with partners from XXX University, institutions, and other collaborators. The Radiation Biology Data Network serves as a central hub for collecting and sharing data relevant to the study of radiation effects on biological systems, including factors associated with radiation sensitivity and resistance, with plans to include radiation toxicity-related factors in the future.</h4>')
                          
                        )
                 )
)
