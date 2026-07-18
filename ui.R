shinyUI(
  fluidPage(
    tags$head(
      tags$meta(name = "viewport", content = "width=device-width, initial-scale=1.0"),
      tags$link(rel = "shortcut icon", href = "img/favicon.png"),
      tags$link(rel = "stylesheet", type = "text/css",
                href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"),
      tags$link(rel = "stylesheet", type = "text/css",
                href = "https://cdn.datatables.net/plug-ins/1.10.25/features/searchHighlight/dataTables.searchHighlight.min.css"),
      tags$script(src = "https://cdn.datatables.net/plug-ins/1.10.25/features/searchHighlight/dataTables.searchHighlight.min.js"),
      tags$script(HTML("
        Shiny.addCustomMessageHandler('reconnect', function(msg) {
          setTimeout(function() { window.location.reload(); }, 3000);
        });
        $(document).on('shiny:disconnected', function() {
          var msg = $('<div>').css({
            position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(255,255,255,0.95)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            zIndex: 9999, fontFamily: 'system-ui, -apple-system, sans-serif',
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
        $(document).on('shown.bs.collapse', '.navbar-collapse', function() {
          $('body').addClass('nav-open');
        });
        $(document).on('hidden.bs.collapse', '.navbar-collapse', function() {
          $('body').removeClass('nav-open');
        });
        $(document).on('click', '#nav-overlay', function() {
          $('.navbar-collapse').collapse('hide');
        });
        $(document).on('click', '.navbar-collapse a', function() {
          if ($(window).width() <= 768) {
            $('.navbar-collapse').collapse('hide');
          }
        });
        $(document).on('mouseenter', '[data-tip]', function() {
          var $el = $(this);
          if ($el.data('tip-active')) return;
          var $tip = $('<div>').css({
            position: 'fixed', zIndex: 99999,
            background: '#2c3e50', color: '#f0f0f0',
            fontSize: '12px', lineHeight: '1.6',
            padding: '10px 14px', borderRadius: '8px',
            maxWidth: '420px', wordWrap: 'break-word',
            textAlign: 'left', pointerEvents: 'none',
            boxShadow: '0 4px 16px rgba(0,0,0,0.25)'
          }).text($el.attr('data-tip')).appendTo('body');
          function pos() {
            var o = $el.offset();
            var t = o.top - $tip.outerHeight() - 8;
            var l = Math.max(4, Math.min(o.left, $(window).width() - $tip.outerWidth() - 4));
            $tip.css({top: t, left: l});
          }
          pos();
          $el.data('tip-active', true);
          $el.on('mouseleave.tip', function() {
            $tip.remove();
            $el.removeData('tip-active').off('mouseleave.tip');
          });
          $(window).on('scroll.tip resize.tip', function() {
            if ($el.data('tip-active')) pos();
          });
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
    tags$div(id = "nav-overlay"),
    navbarPage(
      title = div(style = "padding-left:100px; cursor:pointer;",
        onclick = "Shiny.setInputValue('navbar', 'home', {priority: 'event'});",
        img(src = "img/ChatGPT_logo_RADBIONET_all4.png", height = "75px")
      ),
      id = "navbar",
      selected = "home",
      theme = "styles.css?v=20260719-logos-row",
      collapsible = TRUE,
      fluid = T,
      home,
      data_tab,
      analysis_tab,
      chat_radbio_tab,
      resources_tab,
      about_tab,
      factor_tab
    ),
    div(class = "footer institutional-footer",
        div(class = "institutional-logos",
            div(class = "institutional-logo",
                img(src = "img/jiaotongmedicine.png",
                    alt = "Shanghai Jiao Tong University School of Medicine logo"),
                span("Shanghai Jiao Tong University School of Medicine")
            ),
            div(class = "institutional-logo",
                img(src = "img/ruijin.png",
                    alt = "Ruijin Hospital logo"),
                span("Ruijin Hospital")
            )
        )
    )
  )
)
