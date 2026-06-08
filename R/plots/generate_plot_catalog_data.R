#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

set.seed(20260608)

output_dir <- "data/synthetic"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

clamp <- function(x, low, high) {
  pmin(high, pmax(low, x))
}

simulate_scores <- function(n, primary_mean, primary_sd, tail_mean, tail_sd, tail_share) {
  tail_flag <- rbinom(n, size = 1, prob = tail_share) == 1
  scores <- ifelse(
    tail_flag,
    rnorm(n, mean = tail_mean, sd = tail_sd),
    rnorm(n, mean = primary_mean, sd = primary_sd)
  )
  round(clamp(scores, 0, 100), 1)
}

raincloud_specs <- data.frame(
  support_model = c("Baseline review", "Targeted reteach", "AI practice"),
  n = c(260L, 260L, 260L),
  primary_mean = c(66, 73, 78),
  primary_sd = c(13, 11, 10),
  tail_mean = c(42, 51, 58),
  tail_sd = c(9, 10, 11),
  tail_share = c(0.24, 0.18, 0.16),
  stringsAsFactors = FALSE
)

raincloud_data <- bind_rows(lapply(seq_len(nrow(raincloud_specs)), function(index) {
  spec <- raincloud_specs[index, ]
  n <- spec$n
  score <- simulate_scores(
    n = n,
    primary_mean = spec$primary_mean,
    primary_sd = spec$primary_sd,
    tail_mean = spec$tail_mean,
    tail_sd = spec$tail_sd,
    tail_share = spec$tail_share
  )
  data.frame(
    response_id = sprintf("raincloud_response_%03d_%03d", index, seq_len(n)),
    support_model = spec$support_model,
    assessment_window = sample(
      c("diagnostic", "midcycle", "postcycle"),
      n,
      replace = TRUE,
      prob = c(0.30, 0.38, 0.32)
    ),
    score_percent = score,
    completion_time_minutes = round(clamp(rnorm(n, 38 - score * 0.07, 7.5), 12, 70), 1),
    stringsAsFactors = FALSE
  )
}))

hexbin_n <- 5600L
readiness_index <- c(
  rbeta(round(hexbin_n * 0.72), 5.2, 2.9),
  rbeta(hexbin_n - round(hexbin_n * 0.72), 2.4, 5.6)
) * 100
readiness_index <- sample(readiness_index)
practice_completion_rate <- clamp(
  plogis(-2.2 + readiness_index / 27 + rnorm(hexbin_n, 0, 0.8)),
  0,
  1
)
growth_points <- (
  -15 +
    readiness_index * 0.44 +
    practice_completion_rate * 12 +
    sin(readiness_index / 12) * 4 +
    rnorm(hexbin_n, 0, 8.5)
)
growth_points <- round(clamp(growth_points, -22, 52), 1)

hexbin_data <- data.frame(
  response_id = sprintf("relationship_response_%04d", seq_len(hexbin_n)),
  readiness_index = round(readiness_index, 1),
  practice_completion_rate = round(practice_completion_rate, 3),
  growth_points = growth_points,
  assessment_form = sample(c("Form A", "Form B", "Form C"), hexbin_n, replace = TRUE),
  stringsAsFactors = FALSE
)

calibration_n <- 3200L
task_family <- sample(
  c("Procedural fluency", "Conceptual explanation", "Multi-step modeling"),
  calibration_n,
  replace = TRUE,
  prob = c(0.42, 0.33, 0.25)
)
family_shift <- ifelse(
  task_family == "Procedural fluency",
  0.35,
  ifelse(task_family == "Conceptual explanation", -0.05, -0.32)
)
predicted_mastery_probability <- plogis(
  qlogis(rbeta(calibration_n, 2.4, 2.2)) +
    family_shift +
    rnorm(calibration_n, 0, 0.38)
)
true_mastery_probability <- plogis(
  -0.18 +
    0.84 * qlogis(predicted_mastery_probability) +
    ifelse(task_family == "Multi-step modeling", -0.18, 0) +
    ifelse(task_family == "Procedural fluency", 0.08, 0)
)
observed_mastery <- rbinom(calibration_n, size = 1, prob = true_mastery_probability)

calibration_data <- data.frame(
  case_id = sprintf("calibration_case_%04d", seq_len(calibration_n)),
  task_family = task_family,
  predicted_mastery_probability = round(predicted_mastery_probability, 4),
  true_mastery_probability = round(true_mastery_probability, 4),
  observed_mastery = observed_mastery,
  stringsAsFactors = FALSE
)

write_csv(raincloud_data, file.path(output_dir, "plot_catalog_assessment_scores.csv"))
write_csv(hexbin_data, file.path(output_dir, "plot_catalog_dense_relationships.csv"))
write_csv(calibration_data, file.path(output_dir, "plot_catalog_calibration.csv"))

message("Synthetic plot catalog datasets written to ", output_dir)
