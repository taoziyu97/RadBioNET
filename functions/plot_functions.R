MODERN_COLORS <- c(
  "#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
  "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC",
  "#86BCB6", "#8CD17D", "#B6992D", "#499894", "#D37295",
  "#F1CE63", "#A0CBE8", "#FFBE7D", "#D4A6C8", "#FABFD2"
)

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
    other_n <- sum(df$n[-(1:top_n)])
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

  n_colors <- nrow(df)
  if (n_colors <= length(MODERN_COLORS)) {
    colors <- MODERN_COLORS[1:n_colors]
  } else {
    colors <- colorRampPalette(MODERN_COLORS)(n_colors)
  }

  plot_ly(
    df,
    labels = ~lbl,
    values = ~n,
    type = "pie",
    textinfo = "label+percent",
    textposition = "outside",
    textfont = list(size = 10, color = "#555"),
    hoverinfo = "text",
    hovertext = ~paste0(
      "<b>", .data[[category_col]], "</b><br>",
      "Count: ", n, "<br>",
      "Proportion: ", pct, "%"
    ),
    marker = list(
      colors = colors,
      line = list(color = "#FFFFFF", width = 2)
    ),
    showlegend = FALSE,
    pull = 0.02
  ) %>%
    layout(
      title = list(
        text = paste0("<b>", title, "</b>"),
        font = list(size = 14, color = "#333", family = "Open Sans"),
        x = 0.05,
        xanchor = "left"
      ),
      xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      margin = list(t = 40, b = 20, l = 10, r = 50),
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)",
      font = list(family = "Open Sans")
    )
}
