chat_radbio_tab <- tabPanel(
  title = "Chat-radbio",
  value = "chat_radbio",
  hr(),
  br(),
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      #chat_history_wrapper {
        height: 500px; overflow-y: auto; padding: 15px;
        border: 1px solid #ddd; border-radius: 8px;
        background-color: #f9f9f9; margin-bottom: 15px;
      }
      .msg-user {
        background-color: #098ebb; color: white;
        padding: 10px 15px; border-radius: 18px 18px 4px 18px;
        margin: 8px 0; max-width: 75%;
        float: right; clear: both; word-wrap: break-word;
      }
      .msg-ai {
        background-color: #e8e8e8; color: #333;
        padding: 10px 15px; border-radius: 18px 18px 18px 4px;
        margin: 8px 0; max-width: 75%;
        float: left; clear: both; word-wrap: break-word;
      }
      .msg-system { text-align: center; color: #888; font-size: 12px; clear: both; padding: 5px; }
      .chat-container::after { content: ''; display: table; clear: both; }
      .status-dot { font-size: 10px; vertical-align: middle; }
      .thinking-indicator { font-size: 13px; color: #888; font-style: italic; }
      .thinking-dots span { animation: dot-pulse 1.4s infinite; opacity: 0; font-size: 22px; line-height: 0; }
      .thinking-dots span:nth-child(1) { animation-delay: 0s; }
      .thinking-dots span:nth-child(2) { animation-delay: 0.2s; }
      .thinking-dots span:nth-child(3) { animation-delay: 0.4s; }
      @keyframes dot-pulse {
        0% { opacity: 0; } 50% { opacity: 1; } 100% { opacity: 0; }
      }
    "))
  ),
  column(
    width = 12,
    column(
      width = 8, offset = 2,
      wellPanel(
        style = "background-color: #fff;",
        fluidRow(
          column(8, HTML("<h4><b>Chat-Radbio</b> <span id='model_badge' style='font-size:12px;color:#999;'></span></h4>")),
          column(4, align = "right",
            actionLink("chat_settings_btn", "", icon = icon("cog"),
                       style = "font-size: 18px;", class = "btn btn-default"),
            actionLink("chat_clear", "", icon = icon("trash"),
                       style = "font-size: 18px; margin-left: 8px;", class = "btn btn-default")
          )
        ),
        div(id = "chat_history_wrapper", uiOutput("chat_history_ui")),
        div(
          id = "chat_input_row",
          fluidRow(
            column(10,
              textAreaInput("chat_input", NULL,
                placeholder = "Ask about radiation biology, radiosensitivity factors, molecular mechanisms...",
                width = "100%", rows = 2, resize = "none")
            ),
            column(2, br(),
              actionBttn("chat_send", "Send", style = "fill",
                color = "success", icon = icon("paper-plane"),
                size = "md", block = TRUE)
            )
          )
        ),
        div(style = "font-size: 12px; color: #999; margin-top: 5px;",
            uiOutput("chat_status_ui"))
      )
    )
  )
)
