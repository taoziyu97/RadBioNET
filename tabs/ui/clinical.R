clinical_tab <- tabPanel(
  title = "Clinical",
  value = "clinical",
  hr(),
  br(),
  column(
    width = 12,
    column(
      width = 4,
      pickerInput(
        inputId = "clinical_tumor_type",
        label = "Tumor Type",
        choices = tumor_types,
        selected = tumor_types,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 4,
      pickerInput(
        inputId = "clinical_factor_type",
        label = "Factor Type",
        choices = factor_types,
        selected = factor_types,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 2, style = "padding-top: 25px;",
      actionBttn(
        inputId = "clinical_apply",
        label = "Apply",
        style = "fill",
        color = "success",
        icon = icon("check"),
        size = "sm"
      )
    ),
    column(
      width = 2, style = "padding-top: 25px;",
      actionBttn(
        inputId = "clinical_reset",
        label = "Reset",
        style = "fill",
        color = "danger",
        icon = icon("refresh"),
        size = "sm"
      )
    )
  ),
  br(), hr(),
  column(
    width = 12,
    column(
      width = 6,
      HTML("<center><h4>Effect Direction Distribution</h4></center>"),
      withSpinner(plotlyOutput("clinical_effect"), type = 6)
    ),
    column(
      width = 6,
      HTML("<center><h4>Evidence Level by Tumor Type</h4></center>"),
      withSpinner(plotlyOutput("clinical_evidence_tumor"), type = 6)
    )
  )
)
