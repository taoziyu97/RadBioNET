shinyUI(
  fluidPage(
    tags$head(
      tags$link(rel = "shortcut icon", href = "img/favicon.png"),
      tags$link(rel = "stylesheet", type = "text/css",
                href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"),
      tags$link(rel = "stylesheet", type = "text/css",
                href = "https://fonts.googleapis.com/css?family=Open+Sans|Source+Sans+Pro"),
      tags$script(HTML("
        Shiny.addCustomMessageHandler('reconnect', function(msg) {
          setTimeout(function() { window.location.reload(); }, 3000);
        });
        $(document).on('shiny:disconnected', function() {
          var msg = $('<div>').css({
            position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(255,255,255,0.95)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 9999, fontFamily: 'Open Sans',
            fontSize: '18px', color: '#555', flexDirection: 'column'
          }).html(
            '<div style=\"text-align:center\">' +
            '<div style=\"font-size:48px;margin-bottom:15px\">&#8635;</div>' +
            'Connection lost. Reconnecting...' +
            '<div style=\"font-size:13px;color:#999;margin-top:8px\">' +
            'Please wait a moment</div></div>'
          );
          $('body').append(msg);
          setTimeout(function() { window.location.reload(); }, 5000);
        });
      "))
    ),
    list(tags$head(HTML('<link rel="icon", href="img/favicon.png",
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
      analysis_tab,
      chat_radbio_tab,
      about_tab,
      factor_tab
    ),
    div(class = "footer",
        div(style = "text-align:center; padding: 20px; background-color: #f8f8f8;",
            img(src = "img/jiaotongmedicine.png", height = "50px"),
            img(src = "img/ruijin.png", height = "50px")
        )
    )
  )
)
