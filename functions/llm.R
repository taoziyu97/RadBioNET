library(httr)
library(jsonlite)

DEFAULT_OLLAMA_URL <- "http://localhost:11434"
DEFAULT_OLLAMA_MODEL <- "qwen2.5:7b"

`%||%` <- function(x, y) if (is.null(x)) y else x

llm_ask_ollama <- function(messages, model = DEFAULT_OLLAMA_MODEL,
                            base_url = DEFAULT_OLLAMA_URL,
                            temperature = 0.7, max_tokens = 2048) {
  body <- list(
    model = model,
    messages = messages,
    stream = FALSE,
    options = list(
      temperature = temperature,
      num_predict = max_tokens
    )
  )

  tryCatch(
    {
      resp <- POST(
        url = paste0(base_url, "/api/chat"),
        body = body,
        encode = "json",
        timeout(120)
      )

      if (status_code(resp) != 200) {
        return(list(
          error = paste("Ollama API error:", status_code(resp),
                        content(resp, "text", encoding = "UTF-8"))
        ))
      }

      parsed <- content(resp, "parsed", encoding = "UTF-8")
      list(
        content = parsed$message$content %||% "",
        model = parsed$model %||% "",
        tokens = parsed$eval_count %||% NA_integer_
      )
    },
    error = function(e) {
      list(error = paste("Connection failed:", e$message))
    }
  )
}

llm_ask_openai <- function(messages, model = "deepseek-chat",
                            base_url = "https://api.deepseek.com",
                            api_key = "",
                            temperature = 0.7, max_tokens = 2048) {
  if (nchar(api_key) == 0) {
    return(list(error = "API key is not set"))
  }

  body <- list(
    model = model,
    messages = messages,
    stream = FALSE,
    temperature = temperature,
    max_tokens = max_tokens
  )

  tryCatch(
    {
      resp <- POST(
        url = paste0(gsub("/$", "", base_url), "/v1/chat/completions"),
        body = body,
        encode = "json",
        add_headers(.headers = c(
          "Content-Type" = "application/json",
          "Authorization" = paste("Bearer", api_key)
        )),
        timeout(120)
      )

      if (status_code(resp) != 200) {
        return(list(
          error = paste("API error:", status_code(resp),
                        content(resp, "text", encoding = "UTF-8"))
        ))
      }

      parsed <- content(resp, "parsed", encoding = "UTF-8")
      list(
        content = parsed$choices[[1]]$message$content %||% "",
        model = parsed$model %||% "",
        tokens = c(
          parsed$usage$prompt_tokens %||% NA_integer_,
          parsed$usage$completion_tokens %||% NA_integer_
        )
      )
    },
    error = function(e) {
      list(error = paste("Connection failed:", e$message))
    }
  )
}

llm_available_models <- function(base_url = DEFAULT_OLLAMA_URL) {
  tryCatch(
    {
      resp <- GET(
        url = paste0(base_url, "/api/tags"),
        timeout(10)
      )
      if (status_code(resp) == 200) {
        parsed <- content(resp, "parsed", encoding = "UTF-8")
        sapply(parsed$models, `[[`, "name")
      } else {
        NULL
      }
    },
    error = function(e) NULL
  )
}

llm_check_ollama <- function(base_url = DEFAULT_OLLAMA_URL) {
  tryCatch(
    {
      resp <- GET(url = paste0(base_url, "/api/tags"), timeout(5))
      status_code(resp) == 200
    },
    error = function(e) FALSE
  )
}
