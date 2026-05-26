about_tab <- tabPanel(
  title = "About us",
  value = "about",
  hr(),
  br(),
  column(
    width = 12,
    align = "center",
    wellPanel(
      HTML("<h1><b>About RadBioNet</b></h1>"),
      br(),
      HTML("<h4>
        <b>RadBioNet</b> (Radiation Biology Network) is developed and maintained by the
        <span style='color: #19509A; font-weight: bold;'>Department of Radiation Oncology</span>
        at <b>Ruijin Hospital</b>, Shanghai JiaoTong University School of Medicine.
      </h4>"),
      br(),
      HTML("<h4>
        Our mission is to provide a comprehensive, curated database of factors associated with
        radiation sensitivity and resistance in cancer, supporting the global radiation oncology
        research community.
      </h4>"),
      br(),
      HTML("<h4><b>Contact:</b> Department of Radiation Oncology, Ruijin Hospital, Shanghai JiaoTong University</h4>"),
      br(),
      div(
        img(src = "img/jiaotongmedicine.png", height = "80px", style = "margin: 20px;"),
        img(src = "img/ruijin.png", height = "80px", style = "margin: 20px;")
      )
    )
  )
)
