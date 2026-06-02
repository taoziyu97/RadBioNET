chat_radbio_tab <- tabPanel(
  title = "Chat-radbio",
  value = "chat_radbio",
  hr(),
  fluidRow(
    column(width = 10, offset = 1,
      div(style = "background: linear-gradient(135deg, #f0f7ff, #e8f4f8); border-radius: 14px; padding: 20px 35px; margin-top: 6px; margin-bottom: 20px; border: 1px solid #d0e8f0; box-shadow: 0 3px 15px rgba(9, 142, 187, 0.08);",
        h2(style = "margin: 0 0 6px 0; font-weight: 700; color: #1a5276;", "Chat-Radbio"),
        p(style = "margin: 0 0 6px 0; font-size: 14px; color: #2c3e50; line-height: 1.7;",
          "An AI assistant specialized in radiation biology. Ask questions about radiation sensitivity, resistance mechanisms, treatment outcomes, or any topic covered in the RadBioNet database."),
        p(style = "margin: 0; font-size: 13px; color: #888;",
          icon("info-circle"), " Supports local Ollama models or OpenAI-compatible APIs. Configure via the ",
          tags$b("gear icon"), " above the chat panel.")
      )
    )
  ),
  useShinyjs(),
  tags$head(
    tags$script(HTML("
      Shiny.addCustomMessageHandler('ls_save', function(msg) {
        localStorage.setItem(msg.key, msg.value);
      });
      Shiny.addCustomMessageHandler('ls_remove', function(msg) {
        localStorage.removeItem(msg.key);
      });
    ")),
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
      .welcome-msg { text-align: center; padding: 40px 20px; color: #555; }
      .welcome-msg h3 { font-size: 22px; color: #098ebb; margin-bottom: 12px; font-weight: 700; }
      .welcome-msg p { font-size: 15px; color: #777; line-height: 1.7; margin: 6px 0; }
      #chat_input { font-size: 14px; }
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
                placeholder = "Ask about radiation biology...",
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
