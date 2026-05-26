shinyUI(
  fluidPage(
    tags$head(
      tags$link(rel = "shortcut icon", href = "img/logo.ico"),
      tags$link(rel = "stylesheet", type = "text/css",
                href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"),
      tags$link(rel = "stylesheet", type = "text/css",
                href = "https://fonts.googleapis.com/css?family=Open+Sans|Source+Sans+Pro")
    ),
    list(tags$head(HTML('<link rel="icon", href="img/logo.png",
                        type="image/png" />'))),
    div(style = "padding: 1px 0px; width: '100%'",
        titlePanel(
          title = "", windowTitle = "RadBioNet"
        )
    ),
    navbarPage(
      title = div(img(src = "img/ChatGPT_logo_RADBIONET_all4.png",
                       height = "75px"), style = "padding-left:100px;"),
      id = "navbar",
      selected = "home",
      theme = "styles.css",
      fluid = T,
      home,
      data_tab,
      clinical_tab,
      chat_radbio_tab,
      about_tab
    ),
    div(class = "footer",
        div(style = "text-align:center; padding: 20px; background-color: #f8f8f8;",
            img(src = "img/jiaotongmedicine.png", height = "50px"),
            img(src = "img/ruijin.png", height = "50px")
        )
    )
  )
)
