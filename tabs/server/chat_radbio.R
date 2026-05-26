chat_hist <- reactiveVal(list())
chat_loading <- reactiveVal(FALSE)

render_markdown <- function(text) {
  if (is.null(text) || is.na(text)) return("")
  text <- gsub("\\*\\*(\\S.*?\\S)\\*\\*", "<strong>\\1</strong>", text)
  text <- gsub("\\*(\\S.*?\\S)\\*", "<em>\\1</em>", text)
  text <- gsub("`([^`]+)`", "<code>\\1</code>", text)
  text <- gsub("\\[([^]]+)\\]\\(([^)]+)\\)", "<a href='\\2' target='_blank'>\\1</a>", text)
  text <- gsub("\n{2,}", "</p><p>", text)
  text <- gsub("\n", "<br>", text)
  paste0("<p>", text, "</p>")
}

LLM_DEFAULTS <- list(
  backend = "auto",
  api_url = "https://api.deepseek.com",
  api_key = "",
  model = "deepseek-chat"
)

load_llm_config <- function() {
  cfg <- LLM_DEFAULTS

  env_map <- list(
    backend = Sys.getenv("RADBIO_BACKEND"),
    api_url = Sys.getenv("RADBIO_API_URL"),
    api_key = Sys.getenv("RADBIO_API_KEY"),
    model   = Sys.getenv("RADBIO_MODEL")
  )

  if (nchar(env_map$api_key) > 0) {
    cfg$backend <- if (nchar(env_map$backend) > 0) env_map$backend else "openai"
    cfg$api_url <- if (nchar(env_map$api_url) > 0) env_map$api_url else cfg$api_url
    cfg$api_key <- env_map$api_key
    cfg$model   <- if (nchar(env_map$model) > 0) env_map$model else cfg$model
    return(cfg)
  }

  config_file <- "config/llm_config.R"
  if (file.exists(config_file)) {
    local_cfg <- new.env()
    tryCatch(
      {
        source(config_file, local = local_cfg)
        if (!is.null(local_cfg$LLM_API_KEY) && nchar(local_cfg$LLM_API_KEY) > 0) {
          cfg$backend <- local_cfg$LLM_BACKEND %||% "openai"
          cfg$api_url <- local_cfg$LLM_API_URL %||% cfg$api_url
          cfg$api_key <- local_cfg$LLM_API_KEY
          cfg$model   <- local_cfg$LLM_MODEL %||% cfg$model
        }
      },
      error = function(e) {}
    )
  }

  cfg
}

config <- reactiveValues(
  backend = "auto",
  api_url = "https://api.deepseek.com",
  api_key = "",
  model = "deepseek-chat"
)

{
  init <- load_llm_config()
  config$backend <- init$backend
  config$api_url <- init$api_url
  config$api_key <- init$api_key
  config$model   <- init$model
}

SYSTEM_PROMPT <- paste0(
  "You are Chat-Radbio, a radiation biology AI assistant developed by the Department of ",
  "Radiation Oncology at Ruijin Hospital, Shanghai JiaoTong University. ",
  "You help researchers explore factors associated with radiation sensitivity and resistance in cancer. ",
  "Answer concisely and accurately based on established radiobiology knowledge. ",
  "When asked about specific factors, provide relevant molecular mechanisms when possible. ",
  "You can answer in both English and Chinese."
)

chat_add <- function(role, content) {
  h <- chat_hist()
  h[[length(h) + 1]] <- list(role = role, content = content)
  chat_hist(h)
}

chat_render <- function(hist) {
  if (length(hist) == 0) {
    return(div(class = "msg-system", "Welcome to Chat-Radbio! Ask about radiation biology, radiotherapy sensitivity/resistance factors, and related research."))
  }
  tags <- list()
  for (msg in hist) {
    if (msg$role == "system_msg") {
      tags[[length(tags) + 1]] <- div(class = "msg-system", msg$content)
    } else if (msg$role == "user") {
      tags[[length(tags) + 1]] <- div(class = "msg-user", htmlEscape(msg$content))
    } else if (msg$role == "assistant") {
      tags[[length(tags) + 1]] <- div(
        class = "msg-ai",
        HTML(render_markdown(msg$content))
      )
    }
  }
  do.call(tagList, tags)
}

settings_modal <- function() {
  showModal(modalDialog(
    title = "Chat Settings",
    easyClose = TRUE,
    footer = tagList(
      modalButton("Cancel"),
      actionButton("chat_save_settings", "Save", class = "btn-primary")
    ),
    radioButtons("chat_backend", "Backend",
      choices = c(
        "Auto (try Ollama first, then API)" = "auto",
        "Ollama (local)" = "ollama",
        "OpenAI-compatible API" = "openai"
      ),
      selected = isolate(config$backend)
    ),
    textInput("chat_api_url", "API URL",
      value = isolate(config$api_url),
      placeholder = "e.g. https://api.deepseek.com"
    ),
    passwordInput("chat_api_key", "API Key",
      value = isolate(config$api_key),
      placeholder = "sk-..."
    ),
    textInput("chat_model", "Model Name",
      value = isolate(config$model),
      placeholder = "e.g. deepseek-chat, gpt-3.5-turbo"
    ),
    helpText(
      "For server deployment, set env vars instead:\n",
      "  export RADBIO_API_URL=https://api.deepseek.com\n",
      "  export RADBIO_API_KEY=sk-xxx\n",
      "  export RADBIO_MODEL=deepseek-chat\n\n",
      "Free API options:\n",
      "- DeepSeek: api.deepseek.com\n",
      "- SiliconFlow: api.siliconflow.cn\n",
      "- Groq: api.groq.com"
    )
  ))
}

observeEvent(input$chat_settings_btn, {
  settings_modal()
})

observeEvent(input$chat_save_settings, {
  config$backend <- input$chat_backend
  config$api_url <- input$chat_api_url
  config$api_key <- input$chat_api_key
  config$model <- input$chat_model
  removeModal()
})

info <- reactive({
  ollama_ok <- llm_check_ollama()
  api_ok <- nchar(config$api_key) > 0

  list(
    backend = config$backend,
    ollama_ok = ollama_ok,
    api_ok = api_ok,
    api_configured = api_ok || (config$backend == "openai" && api_ok),
    label = if (ollama_ok) paste("Ollama:", paste(llm_available_models(), collapse = ", "))
           else if (api_ok) paste("API:", config$model)
           else "Not configured"
  )
})

output$chat_history_ui <- renderUI({
  chat_render(chat_hist())
})

output$chat_status_ui <- renderUI({
  i <- info()
  if (chat_loading()) {
    span(icon("spinner", class = "fa-spin"), " Thinking...", style = "color: #098ebb;")
  } else if (i$ollama_ok) {
    span(icon("circle", style = "color: #27ae60;"), " ", i$label, style = "color: #666;")
  } else if (i$api_ok) {
    span(icon("circle", style = "color: #fdc23a;"), " ", i$label, style = "color: #666;")
  } else {
    span(icon("circle", style = "color: #e96449;"), " ", i$label, style = "color: #666;")
  }
})

observe({
  chat_hist()
  session$onFlushed(function() {
    runjs("var el = document.getElementById('chat_history_wrapper'); if (el) el.scrollTop = el.scrollHeight;")
  }, once = TRUE)
})

call_llm <- function(messages) {
  i <- info()

  if (i$backend == "auto") {
    if (i$ollama_ok) {
      return(llm_ask_ollama(messages))
    } else if (i$api_ok) {
      return(llm_ask_openai(messages,
        model = config$model,
        base_url = config$api_url,
        api_key = config$api_key
      ))
    }
  } else if (i$backend == "ollama") {
    return(llm_ask_ollama(messages))
  } else if (i$backend == "openai") {
    if (!i$api_ok) {
      return(list(error = "API Key not set."))
    }
    return(llm_ask_openai(messages,
      model = config$model,
      base_url = config$api_url,
      api_key = config$api_key
    ))
  }

  list(error = paste(
    "No LLM backend configured.\n",
    "Set environment variables on your server:\n",
    "  export RADBIO_API_URL=https://api.deepseek.com\n",
    "  export RADBIO_API_KEY=sk-your-key\n",
    "  export RADBIO_MODEL=deepseek-chat\n\n",
    "Or click the gear icon to configure manually."
  ))
}

observeEvent(input$chat_send, {
  req(input$chat_input)
  if (nchar(trimws(input$chat_input)) == 0) return()
  if (chat_loading()) return()

  user_msg <- trimws(input$chat_input)
  chat_add("user", user_msg)
  updateTextAreaInput(session, "chat_input", value = "")
  chat_loading(TRUE)

  hist <- chat_hist()
  messages <- list(list(role = "system", content = SYSTEM_PROMPT))
  for (msg in hist) {
    if (msg$role %in% c("user", "assistant")) {
      messages[[length(messages) + 1]] <- list(role = msg$role, content = msg$content)
    }
  }

  result <- call_llm(messages)

  if (!is.null(result$error)) {
    chat_add("system_msg", paste("Error:", result$error))
  } else {
    chat_add("assistant", result$content)
  }

  chat_loading(FALSE)
})

observeEvent(input$chat_clear, {
  chat_hist(list())
})
