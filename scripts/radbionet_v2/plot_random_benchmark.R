#!/usr/bin/env Rscript
# Usage: Rscript scripts/radbionet_v2/plot_random_benchmark.R path/to/benchmark
suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L)
directory <- args[[1]]
read_benchmark <- function(file) {
  read.csv(file.path(directory, file), na.strings = "", check.names = FALSE)
}
metrics <- read_benchmark("model_metrics.csv")
cases <- read_benchmark("task_scores.csv")
stopifnot(nrow(metrics) == 10L, nrow(cases) == 115L)
ids <- c("llama", "qwen", "gpt_oss", "deepseek", "claude")
short <- c("Llama 3.3", "Qwen3.5", "GPT-OSS", "DeepSeek", "Claude")
model_labels <- setNames(short, ids)
colors <- setNames(c("#586C99", "#008788", "#A05A63", "#527348", "#6F4B83"), ids)
task_labels <- c(factor_role = "Role", outcome = "Outcome",
                 irradiation_arm = "Arm", unsupported = "Unsupported")
selected_cases <- subset(cases, split == "selection")
task_order <- unique(selected_cases$case_id)

common_theme <- theme_minimal(base_size = 10.5, base_family = "sans") +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11, margin = margin(b = 3)),
        plot.subtitle = element_text(color = "#4B5359", size = 8.2, margin = margin(b = 6)),
        axis.title = element_text(size = 9),
        axis.text = element_text(color = "#262F35"),
        legend.position = "bottom", legend.title = element_blank(),
        plot.tag = element_text(face = "bold"))
theme_set(common_theme)

selected_cases$task <- factor(selected_cases$case_id, levels = rev(task_order))
selected_cases$model <- factor(selected_cases$model_key, levels = ids)
selected_cases$result <- factor(ifelse(selected_cases$case_exact == 1L, "Exact", "Other"),
                                levels = c("Exact", "Other"))
task_names <- setNames(
  paste(task_labels[selected_cases$task_type], selected_cases$pmid, sep = "  "),
  as.character(selected_cases$task)
)
p_a <- ggplot(selected_cases, aes(model, task, fill = result)) +
  geom_tile(color = "white", linewidth = 0.8) +
  geom_text(aes(label = ifelse(result == "Exact", "1", "0"),
                color = result), size = 2.9, show.legend = FALSE) +
  scale_x_discrete(labels = model_labels) +
  scale_y_discrete(labels = task_names) +
  scale_fill_manual(values = c(Exact = "#14757E", Other = "#E7E9EA"),
                    labels = c(Exact = "Exact", Other = "Incomplete match")) +
  scale_color_manual(values = c(Exact = "white", Other = "#4D5962")) +
  labs(title = "Exact task agreement", subtitle = "Held-out selection tasks, one per PMID",
       x = NULL, y = NULL) +
  theme(panel.grid = element_blank())

metrics$model <- factor(metrics$model_key, levels = rev(ids))
metrics$set <- factor(metrics$split, levels = c("development", "selection"),
                      labels = c("Development", "Model selection"))
p_b <- ggplot(metrics, aes(f1, model, fill = set)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.65) +
  geom_text(aes(x = f1 + 0.015, label = sprintf("%.1f%%", 100 * f1)),
            position = position_dodge(width = 0.72), hjust = 0, size = 2.6,
            color = "#262F35", show.legend = FALSE) +
  scale_fill_manual(values = c(Development = "#ABC4D9", "Model selection" = "#117881")) +
  scale_y_discrete(labels = model_labels) +
  scale_x_continuous(limits = c(0, 1), labels = scales::label_percent(),
                     breaks = seq(0, 1, 0.25), expand = expansion(mult = c(0, 0.035))) +
  labs(title = "Strict relation-level F1", subtitle = "Model ranking uses the selection set",
       x = "Micro-F1", y = NULL) + theme(panel.grid.major.y = element_blank())

selected <- subset(metrics, split == "selection")
counts <- do.call(rbind, lapply(
  c(tp = "Matched", fp = "Unmatched prediction", fn = "Missed reference"),
  function(label) {
    key <- c(Matched = "tp", "Unmatched prediction" = "fp", "Missed reference" = "fn")[[label]]
    data.frame(model = selected$model_key, status = label, count = selected[[key]])
  }
))
counts$model <- factor(counts$model, levels = ids)
counts$status <- factor(counts$status, levels = c("Matched", "Unmatched prediction", "Missed reference"))
p_c <- ggplot(counts, aes(model, count, fill = status)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  scale_x_discrete(labels = model_labels) +
  scale_fill_manual(values = c(Matched = "#14757E", "Unmatched prediction" = "#CB8255",
                               "Missed reference" = "#9BACC1")) +
  labs(title = "Matched and unmatched relations", subtitle = "Held-out selection set",
       x = NULL, y = "Relation count") + theme(panel.grid.major.x = element_blank())

if (any(!is.finite(selected$cost_usd) | selected$cost_usd <= 0)) {
  stop("A positive, reported API charge is needed for the cost panel.")
}
p_d <- ggplot(selected, aes(cost_usd, f1, color = model_key)) +
  geom_point(size = 3) +
  scale_color_manual(values = colors, breaks = ids, labels = model_labels) +
  scale_x_log10(labels = scales::label_dollar(accuracy = .001),
                expand = expansion(mult = c(.12, .15))) +
  scale_y_continuous(limits = c(0, 1), labels = scales::label_percent(),
                     breaks = seq(0, 1, 0.25), expand = expansion(mult = c(.01, .045))) +
  labs(title = "F1 and API charge", subtitle = "Nine model-selection requests per model",
       x = "Observed charge (USD, log scale)", y = "Micro-F1") +
  guides(color = guide_legend(nrow = 2, byrow = TRUE))

caption <- sprintf(
  "Seed 2026. Development: %d tasks and %d reference relations. Selection: %d tasks and %d reference relations.\nReference annotations are provisional and based on archived titles and abstracts.",
  metrics$tasks[metrics$split == "development"][1], metrics$reference_relations[metrics$split == "development"][1],
  selected$tasks[1], selected$reference_relations[1]
)
figure <- (p_a | p_b) / (p_c | p_d) +
  plot_annotation(tag_levels = "a", title = "RadBioNET extraction benchmark",
                  caption = caption,
                  theme = theme(plot.title = element_text(size = 15, face = "bold"),
                                plot.caption = element_text(hjust = 0, size = 8)))
ggsave(file.path(directory, "RadBioNET_benchmark_seed2026.pdf"), figure,
       width = 10.2, height = 7.5, units = "in", device = grDevices::pdf, bg = "white")
ggsave(file.path(directory, "RadBioNET_benchmark_seed2026.png"), figure,
       width = 10.2, height = 7.5, units = "in", dpi = 320, bg = "white")
