#!/usr/bin/env Rscript

# Fit public-safe completion models from synthetic section-period summaries.

parse_args <- function(args) {
  parsed <- list(
    input = "data/synthetic/section_period_summary.csv",
    output = "reports/completion_model_summary.csv",
    predictions = "reports/completion_model_predictions.csv"
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

write_coefficients <- function(model, output) {
  coef_table <- as.data.frame(coef(summary(model)))
  coef_table$term <- rownames(coef_table)
  rownames(coef_table) <- NULL
  names(coef_table) <- gsub(" ", "_", names(coef_table))
  coef_table$odds_ratio <- round(exp(coef(model)), 4)
  coef_table$model <- "binomial_completion_glm"
  coef_table <- coef_table[, c("model", "term", setdiff(names(coef_table), c("model", "term")))]
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  write.csv(coef_table, output, row.names = FALSE)
}

write_predictions <- function(model, data, output) {
  predicted <- predict(model, newdata = data, type = "response")
  predictions <- data.frame(
    id = data$id,
    sectionId = data$sectionId,
    course = data$course,
    teacher = data$teacher,
    periodId = data$periodId,
    completion = data$completion,
    predictedCompletion = round(100 * predicted, 1),
    residual = round(data$completion - 100 * predicted, 1),
    stringsAsFactors = FALSE
  )
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  write.csv(predictions, output, row.names = FALSE)
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  if (!file.exists(args$input)) {
    stop(sprintf("Input not found: %s", args$input), call. = FALSE)
  }
  data <- read.csv(args$input, stringsAsFactors = FALSE)
  data$season <- factor(data$season, levels = c("Fall", "Spring"))
  data$course <- factor(data$course)
  data$order_centered <- data$order - min(data$order)

  model <- glm(
    cbind(completed, notCompleted) ~ order_centered + season + course,
    data = data,
    family = binomial()
  )

  write_coefficients(model, args$output)
  write_predictions(model, data, args$predictions)
  message(sprintf("wrote %s", args$output))
  message(sprintf("wrote %s", args$predictions))
}

main()

