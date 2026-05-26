home <- tabPanel(
  title = "Home",
  value = "home",
  hr(),
  br(), br(),
  HTML("<h1><center>WELCOME TO <b>RadBioNet</b></center></h1>"),
  br(), br(),
  column(
    width = 3, align = "center",
    tab_voronoys(
      texto = "Multi-omics Data Integration Module",
      cor = "#098ebb", icon = "brasil.png", id = "analise_geral"
    )
  ),
  column(
    width = 3, align = "center",
    tab_voronoys(
      texto = "Clinical Samples and Biological Resources",
      cor = "#fdc23a", icon = "flag.png", id = "analise_partidos"
    )
  ),
  column(
    width = 3, align = "center",
    tab_voronoys(
      texto = "ChatRaBio and Prognostic Model Module",
      cor = "#e96449", icon = "person.png", id = "analise_candidatos"
    )
  ),
  column(
    width = 3, align = "center",
    tab_voronoys(
      texto = "About us",
      cor = "#818286", icon = "sobre.png", id = "sobre"
    )
  ),
  column(
    width = 12,
    br(), br(), br(), br(),
    wellPanel(
      HTML("<h1><b>RadBioNet</b></h1>"),
      HTML('<h4><b>RadBioNet</b> (Radiation Biology Network) is a resource developed by the Department of Radiation Oncology at <span style="color: #19509A; font-weight: bold;">Ruijin Hospital</span>, Shanghai JiaoTong University. The Radiation Biology Data Network serves as a central hub for collecting and sharing data relevant to the study of radiation effects on biological systems, including factors associated with radiation sensitivity and resistance.</h4>')
    )
  )
)
