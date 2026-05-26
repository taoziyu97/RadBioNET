proportion_pie <- function(data, category_col, title, top_n = 10) {
  df <- data %>%
    group_by(.data[[category_col]]) %>%
    summarise(n = n(), .groups = "drop") %>%
    na.omit() %>%
    arrange(desc(n))

  if (nrow(df) == 0) return(NULL)

  total_n <- sum(df$n)

  if (nrow(df) > top_n) {
    top <- df[1:top_n, ]
    other_n <- sum(df$n[top_n:nrow(df)])
    df <- bind_rows(
      top,
      tibble(!!category_col := "Others", n = other_n)
    )
  }

  df <- df %>%
    mutate(
      pct = round(n / total_n * 100, 1),
      lbl = paste0(.data[[category_col]], "\n", n, " (", pct, "%)")
    )

  colors <- brewer.pal(min(nrow(df), 9), "Set1")
  if (nrow(df) > 9) colors <- colorRampPalette(colors)(nrow(df))

  plot_ly(
    df,
    labels = ~lbl,
    values = ~n,
    type = "pie",
    textinfo = "none",
    hoverinfo = "text",
    text = ~paste0(
      .data[[category_col]], "\n",
      "Count: ", n, "\n",
      "Proportion: ", pct, "%"
    ),
    marker = list(
      colors = colors,
      line = list(color = "#FFFFFF", width = 1)
    ),
    showlegend = TRUE
  ) %>%
    layout(
      title = list(text = title, font = list(size = 13)),
      xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      legend = list(orientation = "h", y = -0.25, font = list(size = 9)),
      margin = list(t = 35, b = 80, l = 10, r = 10)
    )
}
