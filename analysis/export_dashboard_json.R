#!/usr/bin/env Rscript

# Export dashboard-ready JSON from R-generated synthetic CSV artifacts.

require_jsonlite <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "Package `jsonlite` is required to export dashboard JSON. ",
      "Install it with install.packages('jsonlite').",
      call. = FALSE
    )
  }
}

parse_args <- function(args) {
  parsed <- list(
    student_input = "data/synthetic/student_level_assessment.csv",
    summary_input = "data/synthetic/section_period_summary.csv",
    section_input = "data/synthetic/section_metadata.csv",
    calibration_input = "data/synthetic/calibration_summary.csv",
    output = "data/synthetic/assessment-dashboard.json",
    pages_output = NA_character_
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

read_required_csv <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Input not found: %s", path), call. = FALSE)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

scalarize <- function(value) {
  if (length(value) == 1L) {
    if (is.nan(value)) {
      return(NULL)
    }
    return(value[[1]])
  }
  value
}

row_list <- function(row) {
  out <- as.list(row)
  lapply(out, scalarize)
}

skill_columns <- function(data) {
  grep("^skill_", names(data), value = TRUE)
}

skill_label <- function(column) {
  gsub("_", " ", sub("^skill_", "", column))
}

skills_from_row <- function(row, skill_cols) {
  values <- list()
  for (column in skill_cols) {
    value <- row[[column]][[1]]
    if (!is.na(value)) {
      values[[skill_label(column)]] <- value
    }
  }
  values
}

records_to_list <- function(data, include_skills = FALSE) {
  skill_cols <- skill_columns(data)
  base_cols <- setdiff(names(data), skill_cols)
  lapply(seq_len(nrow(data)), function(i) {
    row <- data[i, , drop = FALSE]
    item <- row_list(row[, base_cols, drop = FALSE])
    if (include_skills) {
      item$skills <- skills_from_row(row, skill_cols)
    }
    item
  })
}

sections_to_list <- function(sections) {
  skill_cols <- skill_columns(sections)
  keep_cols <- c("id", "course", "grade", "teacher", "section", "students", "baseline", "growth", "springLift")
  keep_cols <- intersect(keep_cols, names(sections))
  lapply(seq_len(nrow(sections)), function(i) {
    row <- sections[i, , drop = FALSE]
    item <- row_list(row[, keep_cols, drop = FALSE])
    item$skills <- skills_from_row(row, skill_cols)
    item
  })
}

periods_to_list <- function(summary) {
  period_cols <- c("periodId", "periodLabel", "year", "season", "order")
  periods <- unique(summary[, period_cols, drop = FALSE])
  periods <- periods[order(periods$order), ]
  names(periods) <- c("id", "label", "year", "season", "order")
  records_to_list(periods)
}

safe_quantile <- function(values, probability) {
  values <- values[!is.na(values)]
  if (!length(values)) {
    return(0)
  }
  round(as.numeric(quantile(values, probs = probability, names = FALSE)), 1)
}

weighted_average <- function(values, weights) {
  weights <- ifelse(is.na(weights), 0, weights)
  values <- ifelse(is.na(values), 0, values)
  total <- sum(weights)
  if (!total) {
    return(0)
  }
  sum(values * weights) / total
}

build_bands <- function(student_records, summary) {
  period_orders <- sort(unique(summary$order))
  department_lower <- numeric(length(period_orders))
  department_upper <- numeric(length(period_orders))
  network_lower <- numeric(length(period_orders))
  network_upper <- numeric(length(period_orders))
  mastery <- seq(58, by = 2, length.out = length(period_orders))

  for (idx in seq_along(period_orders)) {
    order_value <- period_orders[[idx]]
    rows <- student_records[student_records$order == order_value, ]
    completed_rows <- rows[rows$completed %in% c(TRUE, "TRUE", "true", 1), ]
    department_lower[[idx]] <- safe_quantile(completed_rows$score, 0.20)
    department_upper[[idx]] <- safe_quantile(completed_rows$score, 0.80)
    network_lower[[idx]] <- safe_quantile(rows$score, 0.10)
    network_upper[[idx]] <- safe_quantile(rows$score, 0.90)
  }

  list(
    department = list(
      label = "Student-level p20-p80 completed-score band",
      lower = department_lower,
      upper = department_upper
    ),
    network = list(
      label = "Student-level p10-p90 assigned-score band",
      lower = network_lower,
      upper = network_upper
    ),
    mastery = list(
      label = "Mastery benchmark",
      line = mastery
    )
  )
}

completion_rates <- function(summary) {
  rates <- numeric()
  for (order_value in sort(unique(summary$order))) {
    rows <- summary[summary$order == order_value, ]
    rates <- c(rates, round(weighted_average(rows$completion, rows$students), 1))
  }
  rates
}

calibration_lookup <- function(calibration) {
  values <- as.numeric(calibration$value)
  names(values) <- calibration$metric
  values
}

build_dashboard <- function(student_records, summary, sections, calibration) {
  calibration_values <- calibration_lookup(calibration)
  list(
    generated = as.character(Sys.Date()),
    description = paste(
      "Synthetic multi-year 30-question assessment data generated by an R",
      "analysis pipeline. No real students, rosters, teachers, sections, IDs,",
      "emails, grades, submissions, or school records are included."
    ),
    bootstrap = list(
      privateBootstrapSource = "A private assessment export may be used only to calibrate synthetic distribution shape; no private rows or identifiers are included.",
      scoreColumnPublicName = "Assessment score",
      syntheticItemCount = unname(calibration_values[["synthetic_item_count"]]),
      zeroPolicy = "Most bootstrap zeros are modeled as early non-participation/non-administration; a small true-zero rate remains for realism.",
      completionRatesByPeriod = completion_rates(summary),
      privateDistributionShape = list(
        nonZeroValuesUsedForCalibration = unname(calibration_values[["nonzero_scores"]]),
        zeroValuesUsedForCompletionModeling = unname(calibration_values[["zero_scores"]])
      )
    ),
    periods = periods_to_list(summary),
    bands = build_bands(student_records, summary),
    sections = sections_to_list(sections),
    records = records_to_list(summary, include_skills = TRUE),
    studentRecords = records_to_list(student_records, include_skills = FALSE)
  )
}

main <- function() {
  require_jsonlite()
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  student_records <- read_required_csv(args$student_input)
  summary <- read_required_csv(args$summary_input)
  sections <- read_required_csv(args$section_input)
  calibration <- read_required_csv(args$calibration_input)

  dashboard <- build_dashboard(student_records, summary, sections, calibration)
  dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(dashboard, args$output, pretty = TRUE, auto_unbox = TRUE, na = "null")
  message(sprintf("wrote %s", args$output))

  if (!is.na(args$pages_output) && nzchar(args$pages_output)) {
    dir.create(dirname(args$pages_output), recursive = TRUE, showWarnings = FALSE)
    file.copy(args$output, args$pages_output, overwrite = TRUE)
    message(sprintf("synced dashboard JSON to %s", args$pages_output))
  }
}

main()
