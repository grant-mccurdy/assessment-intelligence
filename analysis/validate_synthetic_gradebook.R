#!/usr/bin/env Rscript

source("analysis/gradebook_reconstruction_lib.R")

args <- parse_cli(
  commandArgs(trailingOnly = TRUE),
  defaults = list(
    report = "reports/gradebook_reconstruction_validation.md",
    analytics_output = "data/synthetic/synthetic_student_scores_long.csv",
    metadata_output = "data/synthetic/synthetic_assignment_metadata.csv"
  ),
  required = c("reference_gradebook", "synthetic_gradebook")
)

reference <- read_gradebook(args$reference_gradebook)
synthetic <- read_gradebook(args$synthetic_gradebook)
reference_profile <- profile_columns(reference)
synthetic_profile <- profile_columns(synthetic)

safe_numeric_values <- function(values) {
  parsed <- numeric_values(values)
  parsed[!is.na(parsed)]
}

safe_mean_gap <- function(reference_values, synthetic_values) {
  reference_values <- reference_values[!is.na(reference_values)]
  synthetic_values <- synthetic_values[!is.na(synthetic_values)]
  if (!length(reference_values) || !length(synthetic_values)) {
    return(NA_real_)
  }
  abs(mean(reference_values) - mean(synthetic_values))
}

safe_sd_gap <- function(reference_values, synthetic_values) {
  reference_values <- reference_values[!is.na(reference_values)]
  synthetic_values <- synthetic_values[!is.na(synthetic_values)]
  if (length(reference_values) < 2L || length(synthetic_values) < 2L) {
    return(NA_real_)
  }
  abs(sd(reference_values) - sd(synthetic_values))
}

all_text_values <- function(data) {
  text_cols <- names(data)[vapply(data, function(col) !is.numeric(col), logical(1))]
  values <- unique(unlist(data[text_cols], use.names = FALSE))
  values <- as.character(values)
  values[!is.na(values) & nzchar(trimws(values))]
}

same_column_count <- ncol(reference) == ncol(synthetic)
same_row_count <- nrow(reference) == nrow(synthetic)
same_numeric_shape <- sum(reference_profile$mostly_numeric) == sum(synthetic_profile$mostly_numeric)
role_counts_reference <- table(reference_profile$role)
role_counts_synthetic <- table(synthetic_profile$role)

identity_roles <- c("student", "id", "sis_user_id", "sis_login_id")
reference_identity_values <- character()
for (role in identity_roles) {
  ref_cols <- reference_profile$column_name[reference_profile$role == role]
  if (!length(ref_cols)) next
  values <- unique(as.character(reference[[ref_cols[[1L]]]]))
  values <- values[!is.na(values) & nzchar(trimws(values))]
  reference_identity_values <- c(reference_identity_values, values)
}
reference_identity_values <- unique(reference_identity_values)

synthetic_text <- all_text_values(synthetic)
identity_leaks <- length(intersect(reference_identity_values, synthetic_text))

analytics_exists <- file.exists(args$analytics_output)
metadata_exists <- file.exists(args$metadata_output)
analytics_rows <- 0L
metadata_rows <- 0L
analytics_identity_leaks <- 0L
analytics_required_columns <- c(
  "synthetic_student_id",
  "synthetic_section",
  "assignment_id",
  "assignment_family",
  "skill_domain",
  "score",
  "completed",
  "missingness_reason",
  "ability_band",
  "engagement_band",
  "risk_band"
)
analytics_has_required_columns <- FALSE

if (analytics_exists) {
  analytics <- read.csv(args$analytics_output, stringsAsFactors = FALSE, check.names = FALSE)
  analytics_rows <- nrow(analytics)
  analytics_has_required_columns <- all(analytics_required_columns %in% names(analytics))
  analytics_identity_leaks <- length(intersect(reference_identity_values, all_text_values(analytics)))
}

if (metadata_exists) {
  metadata <- read.csv(args$metadata_output, stringsAsFactors = FALSE, check.names = FALSE)
  metadata_rows <- nrow(metadata)
}

common_profile_count <- min(nrow(reference_profile), nrow(synthetic_profile))
blank_difference <- abs(reference_profile$blank_rate[seq_len(common_profile_count)] - synthetic_profile$blank_rate[seq_len(common_profile_count)])
blank_similarity <- mean(blank_difference <= 0.15)

score_indices <- which(reference_profile$role == "assignment" & reference_profile$mostly_numeric)
score_indices <- score_indices[score_indices <= ncol(reference) & score_indices <= ncol(synthetic)]
mean_gaps <- numeric()
sd_gaps <- numeric()
if (length(score_indices)) {
  for (idx in score_indices) {
    reference_values <- safe_numeric_values(reference[[idx]])
    synthetic_values <- safe_numeric_values(synthetic[[idx]])
    mean_gaps <- c(mean_gaps, safe_mean_gap(reference_values, synthetic_values))
    sd_gaps <- c(sd_gaps, safe_sd_gap(reference_values, synthetic_values))
  }
}
mean_gaps <- mean_gaps[!is.na(mean_gaps)]
sd_gaps <- sd_gaps[!is.na(sd_gaps)]
mean_gap_similarity <- if (length(mean_gaps)) mean(mean_gaps <= 8) else NA_real_
sd_gap_similarity <- if (length(sd_gaps)) mean(sd_gaps <= 8) else NA_real_

checks <- data.frame(
  Check = c(
    "Column count matches",
    "Row count matches",
    "Numeric column count matches",
    "No identity value overlap in wide gradebook",
    "No identity value overlap in long analytics data",
    "Missingness similarity within 15 percentage points",
    "Assignment mean fidelity within 8 score points",
    "Assignment spread fidelity within 8 score points",
    "Long analytics file exists",
    "Long analytics schema is complete",
    "Assignment metadata file exists"
  ),
  Result = c(
    same_column_count,
    same_row_count,
    same_numeric_shape,
    identity_leaks == 0L,
    analytics_exists && analytics_identity_leaks == 0L,
    blank_similarity >= 0.75,
    !is.na(mean_gap_similarity) && mean_gap_similarity >= 0.75,
    !is.na(sd_gap_similarity) && sd_gap_similarity >= 0.70,
    analytics_exists && analytics_rows > 0L,
    analytics_exists && analytics_has_required_columns,
    metadata_exists && metadata_rows == length(score_indices)
  ),
  Detail = c(
    sprintf("reference=%s synthetic=%s", ncol(reference), ncol(synthetic)),
    sprintf("reference=%s synthetic=%s", nrow(reference), nrow(synthetic)),
    sprintf("reference=%s synthetic=%s", sum(reference_profile$mostly_numeric), sum(synthetic_profile$mostly_numeric)),
    sprintf("overlap_count=%s", identity_leaks),
    sprintf("overlap_count=%s", analytics_identity_leaks),
    sprintf("columns_with_similar_missingness=%.1f%%", 100 * blank_similarity),
    sprintf("assignment_columns_with_similar_mean=%.1f%%", 100 * mean_gap_similarity),
    sprintf("assignment_columns_with_similar_spread=%.1f%%", 100 * sd_gap_similarity),
    sprintf("path=%s rows=%s", args$analytics_output, analytics_rows),
    sprintf("required_columns_present=%s", analytics_has_required_columns),
    sprintf("path=%s rows=%s expected=%s", args$metadata_output, metadata_rows, length(score_indices))
  ),
  stringsAsFactors = FALSE
)

fidelity_rows <- data.frame(
  Metric = c(
    "Median assignment mean gap",
    "Median assignment spread gap",
    "Assignment columns evaluated",
    "Long analytics rows",
    "Assignment metadata rows"
  ),
  Value = c(
    ifelse(length(mean_gaps), round(median(mean_gaps), 2), NA),
    ifelse(length(sd_gaps), round(median(sd_gaps), 2), NA),
    length(score_indices),
    analytics_rows,
    metadata_rows
  ),
  stringsAsFactors = FALSE
)

report <- c(
  "# Gradebook Reconstruction Validation",
  "",
  "This report compares the private reference gradebook shape to the synthetic gradebook outputs without printing private values.",
  "",
  "## Summary Checks",
  "",
  write_markdown_table(checks),
  "",
  "## Distribution Fidelity",
  "",
  write_markdown_table(fidelity_rows),
  "",
  "## Role Counts",
  "",
  "Reference roles:",
  "",
  paste(capture.output(print(role_counts_reference)), collapse = "\n"),
  "",
  "Synthetic roles:",
  "",
  paste(capture.output(print(role_counts_synthetic)), collapse = "\n")
)

dir.create(dirname(args$report), recursive = TRUE, showWarnings = FALSE)
writeLines(report, args$report)
message(sprintf("wrote %s", args$report))

if (!all(checks$Result)) {
  quit(status = 1)
}
