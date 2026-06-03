#!/usr/bin/env Rscript

source("analysis/gradebook_reconstruction_lib.R")

args <- parse_cli(
  commandArgs(trailingOnly = TRUE),
  defaults = list(
    output = "data/synthetic/synthetic_gradebook.csv",
    analytics_output = "data/synthetic/synthetic_student_scores_long.csv",
    metadata_output = "data/synthetic/synthetic_assignment_metadata.csv",
    report = "reports/advanced_synthetic_gradebook_synthesis.md",
    seed = "20260603",
    rows = "same",
    preserve_reference_column_names = FALSE,
    preserve_section_labels = FALSE
  ),
  required = c("reference_gradebook")
)

set.seed(as.integer(args$seed))
reference <- read_gradebook(args$reference_gradebook)
profile <- profile_columns(reference)

row_count <- if (args$rows == "same") nrow(reference) else as.integer(args$rows)
if (is.na(row_count) || row_count <= 0) {
  stop("--rows must be `same` or a positive integer.", call. = FALSE)
}

clamp <- function(x, low, high) {
  pmin(high, pmax(low, x))
}

inv_logit <- function(x) {
  1 / (1 + exp(-x))
}

logit <- function(p) {
  p <- clamp(p, 0.001, 0.999)
  log(p / (1 - p))
}

safe_numeric <- function(values) {
  parsed <- numeric_values(values)
  parsed[!is.na(parsed)]
}

safe_mean <- function(values, fallback = 0) {
  values <- values[!is.na(values)]
  if (!length(values)) {
    return(fallback)
  }
  mean(values)
}

safe_sd <- function(values, fallback = 1) {
  values <- values[!is.na(values)]
  if (length(values) < 2L) {
    return(fallback)
  }
  value <- sd(values)
  if (is.na(value) || value <= 0) fallback else value
}

safe_quantile <- function(values, probability, fallback = NA_real_) {
  values <- values[!is.na(values)]
  if (!length(values)) {
    return(fallback)
  }
  as.numeric(quantile(values, probs = probability, names = FALSE, type = 8))
}

score_family <- function(sequence, total) {
  if (total <= 0L) {
    return("Assessment")
  }
  position <- sequence / total
  if (position <= 0.18) return("Diagnostic")
  if (position <= 0.48) return("Skill Practice")
  if (position <= 0.72) return("Concept Check")
  if (position <= 0.90) return("Unit Assessment")
  "Cumulative Review"
}

skill_domain <- function(sequence) {
  domains <- c(
    "Conceptual Fluency",
    "Procedural Accuracy",
    "Modeling And Application",
    "Evidence And Explanation",
    "Cumulative Retention"
  )
  domains[((sequence - 1L) %% length(domains)) + 1L]
}

public_assignment_id <- function(sequence) {
  sprintf("assignment_%02d", sequence)
}

band_from_rank <- function(values, labels) {
  ranks <- rank(values, ties.method = "average", na.last = "keep")
  pct <- ranks / max(ranks, na.rm = TRUE)
  cut(
    pct,
    breaks = c(-Inf, 0.25, 0.50, 0.75, Inf),
    labels = labels,
    include.lowest = TRUE
  )
}

generate_traits <- function(n) {
  correlation <- matrix(
    c(
      1.00, 0.46, 0.27, -0.36,
      0.46, 1.00, 0.22, -0.58,
      0.27, 0.22, 1.00, -0.20,
      -0.36, -0.58, -0.20, 1.00
    ),
    nrow = 4L,
    byrow = TRUE
  )
  z <- matrix(rnorm(n * 4L), nrow = n)
  correlated <- z %*% chol(correlation)
  traits <- data.frame(
    latent_ability = correlated[, 1L],
    engagement = correlated[, 2L],
    growth_orientation = correlated[, 3L],
    submission_risk = correlated[, 4L],
    stringsAsFactors = FALSE
  )
  traits$ability_band <- as.character(band_from_rank(
    traits$latent_ability,
    c("developing", "approaching", "proficient", "advanced")
  ))
  traits$engagement_band <- as.character(band_from_rank(
    traits$engagement,
    c("low", "emerging", "steady", "high")
  ))
  traits$risk_band <- as.character(band_from_rank(
    traits$submission_risk,
    c("low", "moderate", "elevated", "high")
  ))
  traits
}

section_values <- function(reference, profile, row_count, preserve_labels) {
  section_rows <- which(profile$role == "section")
  if (!length(section_rows)) {
    return(rep("Section A", row_count))
  }
  section_col <- profile$column_name[[section_rows[[1L]]]]
  observed <- reference[[section_col]]
  observed <- observed[!is.na(observed) & nzchar(trimws(observed))]
  if (!length(observed)) {
    return(rep("Section A", row_count))
  }
  if (isTRUE(preserve_labels)) {
    return(sample(observed, row_count, replace = TRUE))
  }
  fake_section_labels(observed, row_count)
}

section_effects <- function(sections, reference, profile) {
  assignment_cols <- profile$column_name[profile$role == "assignment" & profile$mostly_numeric]
  section_rows <- which(profile$role == "section")
  if (!length(assignment_cols) || !length(section_rows)) {
    unique_sections <- sort(unique(sections))
    effects <- rnorm(length(unique_sections), 0, 2.5)
    names(effects) <- unique_sections
    return(effects)
  }

  section_col <- profile$column_name[[section_rows[[1L]]]]
  ref_sections <- reference[[section_col]]
  row_score <- rep(NA_real_, nrow(reference))
  score_matrix <- data.frame(lapply(reference[assignment_cols], numeric_values), check.names = FALSE)
  if (ncol(score_matrix)) {
    row_score <- apply(score_matrix, 1L, function(row) {
      row <- row[!is.na(row)]
      if (!length(row)) NA_real_ else mean(row)
    })
  }

  section_means <- tapply(row_score, ref_sections, mean, na.rm = TRUE)
  section_means <- section_means[!is.na(section_means)]
  if (!length(section_means)) {
    unique_sections <- sort(unique(sections))
    effects <- rnorm(length(unique_sections), 0, 2.5)
    names(effects) <- unique_sections
    return(effects)
  }

  centered <- as.numeric(section_means - mean(section_means))
  unique_sections <- sort(unique(sections))
  mapped <- rep(centered, length.out = length(unique_sections))
  names(mapped) <- unique_sections
  mapped
}

build_assignment_metadata <- function(reference, profile, output_names) {
  assignment_indices <- which(profile$role == "assignment")
  score_indices <- assignment_indices[profile$mostly_numeric[assignment_indices]]
  rows <- list()
  total <- length(score_indices)
  if (!total) {
    return(data.frame())
  }

  global_mean <- safe_mean(profile$mean[score_indices], 75)
  global_sd <- safe_sd(profile$sd[score_indices], 12)
  for (sequence in seq_along(score_indices)) {
    idx <- score_indices[[sequence]]
    col_name <- profile$column_name[[idx]]
    observed <- safe_numeric(reference[[col_name]])
    center <- ifelse(is.na(profile$mean[[idx]]), global_mean, profile$mean[[idx]])
    spread <- ifelse(is.na(profile$sd[[idx]]) || profile$sd[[idx]] <= 0, global_sd, profile$sd[[idx]])
    low <- ifelse(is.na(profile$min[[idx]]), 0, profile$min[[idx]])
    high <- ifelse(is.na(profile$max[[idx]]), 100, profile$max[[idx]])
    rows[[sequence]] <- data.frame(
      source_column_index = idx,
      assignment_id = public_assignment_id(sequence),
      assignment_label = output_names[[idx]],
      assignment_sequence = sequence,
      assignment_family = score_family(sequence, total),
      skill_domain = skill_domain(sequence),
      reference_nonblank_count = length(observed),
      reference_blank_rate = round(profile$blank_rate[[idx]], 4),
      reference_mean = round(center, 3),
      reference_sd = round(spread, 3),
      reference_min = round(low, 3),
      reference_p25 = round(safe_quantile(observed, 0.25, center), 3),
      reference_p50 = round(safe_quantile(observed, 0.50, center), 3),
      reference_p75 = round(safe_quantile(observed, 0.75, center), 3),
      reference_max = round(high, 3),
      difficulty_index = round((global_mean - center) / max(global_sd, 1), 3),
      discrimination = round(clamp(spread / max(global_sd, 1), 0.55, 1.65), 3),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

map_to_reference_distribution <- function(raw_scores, observed, low, high) {
  observed <- observed[!is.na(observed)]
  if (length(observed) < 8L) {
    return(clamp(raw_scores, low, high))
  }
  probabilities <- (rank(raw_scores, ties.method = "average") - 0.5) / length(raw_scores)
  mapped <- as.numeric(quantile(observed, probs = probabilities, names = FALSE, type = 8))
  clamp(mapped, low, high)
}

missing_reason <- function(completed, score, risk_band) {
  if (isTRUE(completed)) {
    return(ifelse(!is.na(score) && score <= 0, "completed_zero_score", "completed"))
  }
  if (risk_band %in% c("elevated", "high")) {
    return(sample(c("missing_submission", "late_or_incomplete"), 1L, prob = c(0.65, 0.35)))
  }
  sample(c("not_administered", "excused_or_absent", "missing_submission"), 1L, prob = c(0.55, 0.30, 0.15))
}

generate_assignment_scores <- function(reference, profile, output_names, sections, traits) {
  metadata <- build_assignment_metadata(reference, profile, output_names)
  row_count <- nrow(traits)
  if (!nrow(metadata)) {
    return(list(
      score_matrix = matrix(nrow = row_count, ncol = 0L),
      metadata = metadata,
      long_records = data.frame()
    ))
  }

  effects <- section_effects(sections, reference, profile)
  section_effect <- unname(effects[sections])
  section_effect[is.na(section_effect)] <- 0

  score_matrix <- matrix(NA_real_, nrow = row_count, ncol = nrow(metadata))
  long_records <- vector("list", row_count * nrow(metadata))
  cursor <- 1L

  for (j in seq_len(nrow(metadata))) {
    meta <- metadata[j, ]
    idx <- meta$source_column_index
    col_name <- profile$column_name[[idx]]
    observed <- safe_numeric(reference[[col_name]])
    low <- meta$reference_min
    high <- meta$reference_max
    center <- meta$reference_mean
    spread <- max(meta$reference_sd, 1)
    sequence_scaled <- if (nrow(metadata) == 1L) 0 else (meta$assignment_sequence - 1L) / (nrow(metadata) - 1L)

    raw <- center +
      traits$latent_ability * 7.5 * meta$discrimination +
      traits$engagement * 2.8 +
      traits$growth_orientation * sequence_scaled * 5.0 +
      section_effect * 0.65 -
      meta$difficulty_index * 3.5 +
      rnorm(row_count, 0, max(2.5, spread * 0.35))

    scores <- round(map_to_reference_distribution(raw, observed, low, high), 2)
    base_blank <- clamp(meta$reference_blank_rate, 0.001, 0.985)
    missing_probability <- inv_logit(
      logit(base_blank) +
        traits$submission_risk * 0.95 -
        traits$engagement * 0.55 -
        traits$latent_ability * 0.15 +
        sequence_scaled * 0.18
    )
    completed <- runif(row_count) > missing_probability

    zero_rate <- if (length(observed)) mean(observed <= low + 0.0001, na.rm = TRUE) else 0
    zero_rate <- clamp(ifelse(is.na(zero_rate), 0, zero_rate), 0, 0.12)
    true_zero <- completed & runif(row_count) < inv_logit(logit(max(zero_rate, 0.001)) + traits$submission_risk * 0.35)
    scores[true_zero] <- low
    scores[!completed] <- NA_real_
    score_matrix[, j] <- scores

    for (i in seq_len(row_count)) {
      long_records[[cursor]] <- data.frame(
        synthetic_student_id = sprintf("synthetic_student_%03d", i),
        synthetic_section = sections[[i]],
        assignment_id = meta$assignment_id,
        assignment_label = meta$assignment_label,
        assignment_sequence = meta$assignment_sequence,
        assignment_family = meta$assignment_family,
        skill_domain = meta$skill_domain,
        reference_column_index = idx,
        score = scores[[i]],
        score_min = low,
        score_max = high,
        score_percent = ifelse(is.na(scores[[i]]) || high <= low, NA_real_, round(100 * (scores[[i]] - low) / (high - low), 2)),
        completed = completed[[i]],
        missingness_reason = missing_reason(completed[[i]], scores[[i]], traits$risk_band[[i]]),
        ability_band = traits$ability_band[[i]],
        engagement_band = traits$engagement_band[[i]],
        risk_band = traits$risk_band[[i]],
        stringsAsFactors = FALSE
      )
      cursor <- cursor + 1L
    }
  }

  list(
    score_matrix = score_matrix,
    metadata = metadata,
    long_records = do.call(rbind, long_records)
  )
}

synthetic_text_values <- function(n, blank_rate) {
  values <- sample(
    c("Complete", "Submitted", "Exempt", "Needs Review"),
    n,
    replace = TRUE,
    prob = c(0.48, 0.34, 0.08, 0.10)
  )
  values[runif(n) < clamp(blank_rate, 0, 0.98)] <- ""
  values
}

write_synthesis_report <- function(path, reference, profile, synthetic, metadata, long_records) {
  summary_rows <- data.frame(
    Metric = c(
      "Reference rows",
      "Synthetic rows",
      "Columns preserved",
      "Numeric assignment columns synthesized",
      "Long-form score records",
      "Synthetic sections",
      "Synthetic assignment families"
    ),
    Value = c(
      nrow(reference),
      nrow(synthetic),
      ncol(synthetic),
      nrow(metadata),
      nrow(long_records),
      length(unique(long_records$synthetic_section)),
      length(unique(long_records$assignment_family))
    ),
    stringsAsFactors = FALSE
  )

  method_rows <- data.frame(
    Technique = c(
      "Schema reconstruction",
      "Latent trait simulation",
      "Distribution mapping",
      "Missingness modeling",
      "Analytics reshaping",
      "Privacy protection"
    ),
    Implementation = c(
      "Column order, standard Canvas fields, numeric-like roles, blank rates, and score ranges are profiled from the private reference.",
      "Synthetic students receive correlated ability, engagement, growth, and submission-risk factors.",
      "Generated scores are rank-mapped onto observed reference quantiles by assignment column without copying rows.",
      "Completion is modeled separately from low performance using assignment blank rates and synthetic engagement/risk factors.",
      "The wide Canvas-style gradebook is converted into a long student-assignment record table for modeling and dashboards.",
      "Identity fields, student labels, IDs, SIS IDs, login IDs, section labels, and assignment labels are generated or sanitized by default."
    ),
    stringsAsFactors = FALSE
  )

  report <- c(
    "# Advanced Synthetic Gradebook Synthesis",
    "",
    "This public-safe report documents the R workflow used to reconstruct a realistic synthetic gradebook from private reference structure.",
    "It prints aggregate workflow properties only; it does not print private rows, identifiers, section labels, or assignment names.",
    "",
    "## Output Summary",
    "",
    write_markdown_table(summary_rows),
    "",
    "## R Synthesis Techniques",
    "",
    write_markdown_table(method_rows),
    "",
    "## Outputs",
    "",
    "- `data/synthetic/synthetic_gradebook.csv`: Canvas-style wide synthetic gradebook.",
    "- `data/synthetic/synthetic_student_scores_long.csv`: analytics-ready student-assignment score records.",
    "- `data/synthetic/synthetic_assignment_metadata.csv`: public-safe assignment families, sequence, domain, and calibration metrics.",
    "",
    "## Public Boundary",
    "",
    "The public workflow can be shown in the repository. The reference gradebook path and any detailed private profile remain local/private."
  )

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(report, path)
}

output_names <- vapply(seq_len(nrow(profile)), function(i) {
  row <- profile[i, ]
  if (isTRUE(args$preserve_reference_column_names)) {
    row$column_name
  } else {
    public_column_label(row)
  }
}, character(1))

synthetic <- data.frame(matrix(nrow = row_count, ncol = nrow(profile)))
names(synthetic) <- output_names

traits <- generate_traits(row_count)
sections <- section_values(reference, profile, row_count, isTRUE(args$preserve_section_labels))
generated <- generate_assignment_scores(reference, profile, output_names, sections, traits)
assignment_indices <- which(profile$role == "assignment")
score_assignment_indices <- generated$metadata$source_column_index

row_means <- if (ncol(generated$score_matrix)) {
  apply(generated$score_matrix, 1L, function(values) {
    values <- values[!is.na(values)]
    if (!length(values)) NA_real_ else mean(values)
  })
} else {
  round(clamp(75 + traits$latent_ability * 9 + traits$engagement * 4, 0, 100), 2)
}
grade_values <- vapply(row_means, grade_from_score, character(1))

for (i in seq_len(nrow(profile))) {
  role <- profile$role[[i]]
  out_col <- names(synthetic)[[i]]
  if (role == "student") {
    synthetic[[out_col]] <- sprintf("Synthetic Student %03d", seq_len(row_count))
  } else if (role == "id") {
    synthetic[[out_col]] <- as.character(900000L + seq_len(row_count))
  } else if (role == "sis_user_id") {
    synthetic[[out_col]] <- sprintf("SYN%06d", seq_len(row_count))
  } else if (role == "sis_login_id") {
    synthetic[[out_col]] <- sprintf("synthetic%03d", seq_len(row_count))
  } else if (role == "section") {
    synthetic[[out_col]] <- sections
  } else if (role %in% c("current_score", "final_score", "unposted_final_score")) {
    synthetic[[out_col]] <- round(row_means, 2)
  } else if (role %in% c("current_grade", "final_grade")) {
    synthetic[[out_col]] <- grade_values
  } else if (role == "assignment" && i %in% score_assignment_indices) {
    j <- match(i, score_assignment_indices)
    synthetic[[out_col]] <- generated$score_matrix[, j]
  } else if (role == "assignment") {
    synthetic[[out_col]] <- synthetic_text_values(row_count, profile$blank_rate[[i]])
  }
}

dir.create(dirname(args$output), recursive = TRUE, showWarnings = FALSE)
write.csv(synthetic, args$output, row.names = FALSE, na = "")

dir.create(dirname(args$analytics_output), recursive = TRUE, showWarnings = FALSE)
write.csv(generated$long_records, args$analytics_output, row.names = FALSE, na = "")

dir.create(dirname(args$metadata_output), recursive = TRUE, showWarnings = FALSE)
write.csv(generated$metadata, args$metadata_output, row.names = FALSE, na = "")

write_synthesis_report(args$report, reference, profile, synthetic, generated$metadata, generated$long_records)

message(sprintf("wrote %s", args$output))
message(sprintf("wrote %s", args$analytics_output))
message(sprintf("wrote %s", args$metadata_output))
message(sprintf("wrote %s", args$report))
message(sprintf("synthetic rows: %s", row_count))
message(sprintf("synthetic columns: %s", ncol(synthetic)))
message(sprintf("long-form synthetic score records: %s", nrow(generated$long_records)))
