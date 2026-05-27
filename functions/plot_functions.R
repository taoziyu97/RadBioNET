MODERN_COLORS <- c(
  "#4E79A7", "#F28E2B", "#E15759", "#76B7B2", "#59A14F",
  "#EDC948", "#B07AA1", "#FF9DA7", "#9C755F", "#BAB0AC",
  "#86BCB6", "#8CD17D", "#B6992D", "#499894", "#D37295",
  "#F1CE63", "#A0CBE8", "#FFBE7D", "#D4A6C8", "#FABFD2"
)

proportion_pie <- function(data, category_col, title, top_n = 10) {
  df <- data
  df[[category_col]][is.na(df[[category_col]])] <- "Unknown"
  df <- df %>%
    group_by(.data[[category_col]]) %>%
    summarise(n = n(), .groups = "drop") %>%
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
    mutate(pct = round(n / total_n * 100, 1))

  n_colors <- nrow(df)
  if (n_colors <= length(MODERN_COLORS)) {
    colors <- MODERN_COLORS[1:n_colors]
  } else {
    colors <- colorRampPalette(MODERN_COLORS)(n_colors)
  }

  plot_ly(
    df,
    labels = ~.data[[category_col]],
    values = ~n,
    type = "pie",
    hole = 0.4,
    domain = list(x = c(0.1, 0.9), y = c(0, 1)),
    textinfo = "label",
    textposition = "outside",
    textfont = list(size = 8, color = "#555", family = "Open Sans"),
    hoverinfo = "text",
    hovertext = ~paste0(
      "<b>", .data[[category_col]], "</b><br>",
      "n = ", n, " (", pct, "%)"
    ),
    marker = list(
      colors = colors,
      line = list(color = "#FFFFFF", width = 1.5)
    ),
    showlegend = FALSE
  ) %>%
    layout(
      title = list(
        text = paste0("<b>", title, "</b>"),
        font = list(size = 12, color = "#333", family = "Open Sans"),
        x = 0.5,
        xanchor = "center"
      ),
      xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
      margin = list(t = 30, b = 5, l = 5, r = 5),
      paper_bgcolor = "rgba(0,0,0,0)",
      plot_bgcolor = "rgba(0,0,0,0)",
      font = list(family = "Open Sans"),
      annotations = list(
        text = paste0("<b>", total_n, "</b>"),
        font = list(size = 16, color = "#555", family = "Open Sans"),
        showarrow = FALSE,
        x = 0.5, y = 0.5
      )
    )
}
