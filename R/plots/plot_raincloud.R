#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

source("R/plots/plot_theme.R")

build_cloud_polygons <- function(data, group_levels) {
  bind_rows(lapply(seq_along(group_levels), function(group_index) {
    group_label <- group_levels[[group_index]]
    values <- data$score_percent[data$support_model == group_label]
    density_estimate <- density(values, from = 0, to = 100, n = 256, adjust = 0.9)
    cloud_height <- density_estimate$y / max(density_estimate$y) * 0.34

    data.frame(
      support_model = group_label,
      group_index = group_index,
      score_percent = c(density_estimate$x, rev(density_estimate$x)),
      y = c(group_index + cloud_height, rep(group_index, length(cloud_height))),
      stringsAsFactors = FALSE
    )
  }))
}

build_box_summaries <- function(data) {
  data %>%
    group_by(support_model, group_index) %>%
    summarise(
      q1 = quantile(score_percent, 0.25),
      median = median(score_percent),
      q3 = quantile(score_percent, 0.75),
      mean_score = mean(score_percent),
      iqr = IQR(score_percent),
      min_score = min(score_percent),
      max_score = max(score_percent),
      .groups = "drop"
    ) %>%
    mutate(
      whisker_low = pmax(min_score, q1 - 1.5 * iqr),
      whisker_high = pmin(max_score, q3 + 1.5 * iqr)
    )
}

plot_raincloud <- function(
    data_path = "data/synthetic/plot_catalog_assessment_scores.csv",
    output_path = "outputs/plots/raincloud_assessment_distribution.png") {
  data <- read_csv(data_path, show_col_types = FALSE)
  group_levels <- c("Baseline review", "Targeted reteach", "AI practice")
  data <- data %>%
    mutate(
      support_model = factor(support_model, levels = group_levels),
      group_index = as.integer(support_model)
    )

  set.seed(20260608)
  data <- data %>%
    mutate(point_y = group_index - 0.24 + runif(n(), -0.075, 0.075))

  cloud_data <- build_cloud_polygons(data, group_levels)
  box_data <- build_box_summaries(data)

  plot <- ggplot() +
    geom_polygon(
      data = cloud_data,
      aes(
        x = score_percent,
        y = y,
        group = support_model,
        fill = support_model
      ),
      alpha = 0.34,
      color = NA
    ) +
    geom_point(
      data = data,
      aes(
        x = score_percent,
        y = point_y,
        color = support_model
      ),
      alpha = 0.34,
      size = 0.9,
      stroke = 0
    ) +
    geom_segment(
      data = box_data,
      aes(x = whisker_low, xend = whisker_high, y = group_index, yend = group_index),
      color = "#17212B",
      linewidth = 0.45
    ) +
    geom_rect(
      data = box_data,
      aes(xmin = q1, xmax = q3, ymin = group_index - 0.065, ymax = group_index + 0.065),
      fill = "white",
      color = "#17212B",
      linewidth = 0.45
    ) +
    geom_segment(
      data = box_data,
      aes(x = median, xend = median, y = group_index - 0.065, yend = group_index + 0.065),
      color = "#17212B",
      linewidth = 0.55
    ) +
    geom_point(
      data = box_data,
      aes(x = mean_score, y = group_index),
      fill = "#F0E442",
      color = "#17212B",
      shape = 21,
      size = 2.2,
      stroke = 0.45
    ) +
    scale_fill_manual(values = plot_catalog_colors, guide = "none") +
    scale_color_manual(values = plot_catalog_colors, guide = "none") +
    scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 20)) +
    scale_y_continuous(
      breaks = seq_along(group_levels),
      labels = group_levels,
      expand = expansion(mult = c(0.12, 0.18))
    ) +
    labs(
      title = "Score distributions by support model",
      subtitle = "Density, raw synthetic responses, quartiles, and means in one view.",
      x = "Score percent",
      y = NULL,
      caption = "Synthetic data only. No student, school, roster, or private records are used."
    ) +
    theme_plot_catalog()

  save_plot_catalog(plot, output_path, width = 8.0, height = 4.8)
  invisible(plot)
}

if (identical(sys.nframe(), 0L)) {
  plot_raincloud()
}
