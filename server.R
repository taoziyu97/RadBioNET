shinyServer(function(input, output, session) {
  source("tabs/server/home.R", local = TRUE)
  source("tabs/server/data.R", local = TRUE)
  source("tabs/server/clinical.R", local = TRUE)
  source("tabs/server/chat_radbio.R", local = TRUE)
  source("tabs/server/about.R", local = TRUE)
})
