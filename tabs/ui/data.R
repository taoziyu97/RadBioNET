data_tab <- tabPanel(
  title = "Data",
  value = "data",
  hr(),
  br(),
  column(
    width = 12,
    column(
      width = 2,
      pickerInput(
        inputId = "filter_tumor_type",
        label = "Tumor Type",
        choices = tumor_types,
        selected = tumor_types,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 2,
      pickerInput(
        inputId = "filter_tumor_subtype",
        label = "Tumor Subtype",
        choices = tumor_subtypes,
        selected = tumor_subtypes,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 2,
      pickerInput(
        inputId = "filter_radiation_type",
        label = "Radiation Type",
        choices = radiation_types,
        selected = radiation_types,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 2,
      pickerInput(
        inputId = "filter_factor_type",
        label = "Factor Type",
        choices = factor_types,
        selected = factor_types,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 2,
      pickerInput(
        inputId = "filter_evidence",
        label = "Evidence Level",
        choices = evidence_levels,
        selected = evidence_levels,
        options = list(`live-search` = TRUE, `actions-box` = TRUE),
        multiple = TRUE
      )
    ),
    column(
      width = 1, style = "padding-top: 25px;",
      actionBttn(
        inputId = "btn_apply",
        label = "Apply",
        style = "fill",
        color = "success",
        icon = icon("check"),
        size = "sm"
      )
    ),
    column(
      width = 1, style = "padding-top: 25px;",
      actionBttn(
        inputId = "btn_reset",
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
    column(width = 4, withSpinner(plotlyOutput("chart_tumor_type"), type = 6)),
    column(width = 4, withSpinner(plotlyOutput("chart_tumor_subtype"), type = 6)),
    column(width = 4, withSpinner(plotlyOutput("chart_radiation_type"), type = 6))
  ),
  br(),
  column(
    width = 12,
    column(width = 6, withSpinner(plotlyOutput("chart_factor_type"), type = 6)),
    column(width = 6, withSpinner(plotlyOutput("chart_evidence"), type = 6))
  ),
  br(), hr(),
  column(
    width = 12,
    HTML("<center><h4>Database Records</h4></center>"),
    br(),
    withSpinner(DTOutput("data_table"), type = 6)
  )
)
