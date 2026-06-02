#!/usr/bin/env Rscript

# Fit public-safe growth models from synthetic section-period summaries.

parse_args <- function(args) {
  parsed <- list(
    input = "data/synthetic/section_period_summary.csv",
    output = "reports/growth_model_summary.csv",
    diagnostics = "reports/growth_model_diagnostics.csv"
  )
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--") || i == length(args)) {
      stop(sprintf("Invalid argument near: %s", key), call. = FALSE)
    }
    name <- gsub("-", "_", sub("^--", "", key))
    parsed[[name]] <- args[[i + 1L]]
    i <- i + 2L
  }
  parsed
}

write_coefficients <- function(model, output, model_name) {
  coef_table <- as.data.frame(coef(summary(model)))
  coef_table$term <- rownames(coef_table)
  rownames(coef_table) <- NULL
  names(coef_table) <- gsub(" ", "_", names(coef_table))
  coef_table$model <- model_name
  coef_table <- coef_table[, c("model", "term", setdiff(names(coef_table), c("model", "term")))]
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  write.csv(coef_table, output, row.names = FALSE)
}

write_diagnostics <- function(model, data, output) {
  predictions <- predict(model, newdata = data)
  diagnostics <- data.frame(
    id = data$id,
    sectionId = data$sectionId,
    course = data$course,
    teacher = data$teacher,
    periodId = data$periodId,
    score = data$score,
    fitted = round(predictions, 2),
    residual = round(data$score - predictions, 2),
    stringsAsFactors = FALSE
  )
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  write.csv(diagnostics, output, row.names = FALSE)
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  if (!file.exists(args$input)) {
    stop(sprintf("Input not found: %s", args$input), call. = FALSE)
  }
  data <- read.csv(args$input, stringsAsFactors = FALSE)
  data$season <- factor(data$season, levels = c("Fall", "Spring"))
  data$course <- factor(data$course)
  data$teacher <- factor(data$teacher)
  data$order_centered <- data$order - min(data$order)

  model <- lm(
    score ~ order_centered + season + course + completion,
    data = data,
    weights = pmax(data$completed, 1)
  )

  write_coefficients(model, args$output, "weighted_lm_growth")
  write_diagnostics(model, data, args$diagnostics)
  message(sprintf("wrote %s", args$output))
  message(sprintf("wrote %s", args$diagnostics))
}

main()

