#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
})

source("R/plots/plot_theme.R")

summarize_calibration <- function(data, bins = seq(0, 1, by = 0.1)) {
  data %>%
    mutate(
      probability_bin = cut(
        predicted_mastery_probability,
        breaks = bins,
        include.lowest = TRUE,
        right = FALSE
      )
    ) %>%
    group_by(probability_bin) %>%
    summarise(
      mean_predicted = mean(predicted_mastery_probability),
      observed_rate = mean(observed_mastery),
      n = n(),
      standard_error = sqrt(observed_rate * (1 - observed_rate) / n),
      .groups = "drop"
    ) %>%
    mutate(
      lower = pmax(0, observed_rate - 1.96 * standard_error),
      upper = pmin(1, observed_rate + 1.96 * standard_error)
    )
}

plot_calibration <- function(
    data_path = "data/synthetic/plot_catalog_calibration.csv",
    output_path = "outputs/plots/calibration_predicted_mastery.png") {
  data <- read_csv(data_path, show_col_types = FALSE)
  calibration_summary <- summarize_calibration(data)

  plot <- ggplot(calibration_summary, aes(x = mean_predicted, y = observed_rate)) +
    geom_abline(slope = 1, intercept = 0, color = "#46515C", linetype = "dashed", linewidth = 0.65) +
    geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.015, color = "#0072B2", linewidth = 0.55) +
    geom_line(color = "#0072B2", linewidth = 0.85) +
    geom_point(aes(size = n), fill = "#F0E442", color = "#17212B", shape = 21, stroke = 0.45) +
    scale_x_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    scale_y_continuous(labels = percent_format(accuracy = 1), limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    scale_size_continuous(range = c(2.5, 6), name = "Cases") +
    coord_equal() +
    labs(
      title = "Predicted mastery calibration",
      subtitle = "Bins below the dashed line indicate overconfident predictions.",
      x = "Mean predicted mastery probability",
      y = "Observed mastery rate",
      caption = "Synthetic data only. Error bars are approximate 95% binomial intervals."
    ) +
    theme_plot_catalog()

  save_plot_catalog(plot, output_path, width = 6.7, height = 5.4)
  invisible(plot)
}

if (identical(sys.nframe(), 0L)) {
  plot_calibration()
}
