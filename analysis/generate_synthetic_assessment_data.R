#!/usr/bin/env Rscript

# Generate public-safe synthetic assessment data.
#
# This script is designed as the R analysis/build layer for a static GitHub
# Pages dashboard. It may read a private bootstrap CSV locally for distribution
# calibration, but it writes only fake students, fake teachers, fake sections,
# and synthetic scores.

item_count <- 30L
default_seed <- 20260602L

periods <- data.frame(
  id = c(
    "2022-fall", "2023-spring", "2023-fall", "2024-spring",
    "2024-fall", "2025-spring", "2025-fall", "2026-spring"
  ),
  label = c(
    "Fall 2022", "Spring 2023", "Fall 2023", "Spring 2024",
    "Fall 2024", "Spring 2025", "Fall 2025", "Spring 2026"
  ),
  year = c(2022L, 2023L, 2023L, 2024L, 2024L, 2025L, 2025L, 2026L),
  season = c("Fall", "Spring", "Fall", "Spring", "Fall", "Spring", "Fall", "Spring"),
  order = seq_len(8L),
  stringsAsFactors = FALSE
)

section_blueprints <- data.frame(
  id = c(
    "alg1-9-a", "alg1-9-b", "alg1-9-c",
    "geo-10-a", "geo-10-b", "geo-10-c",
    "precalc-11-a", "precalc-11-b", "precalc-12-a",
    "stats-11-a", "stats-12-a", "stats-12-b"
  ),
  course = c(
    "Algebra 1", "Algebra 1", "Algebra 1",
    "Geometry", "Geometry", "Geometry",
    "Precalculus", "Precalculus", "Precalculus",
    "AP Statistics", "AP Statistics", "AP Statistics"
  ),
  grade = c("9", "9", "9", "10", "10", "10", "11", "11", "12", "11", "12", "12"),
  teacher = paste("Teacher", c("A", "B", "C", "A", "D", "E", "B", "F", "F", "C", "E", "D")),
  section = c("A", "B", "C", "A", "B", "C", "A", "B", "A", "A", "A", "B"),
  students = c(27L, 24L, 29L, 26L, 30L, 23L, 22L, 20L, 18L, 21L, 19L, 17L),
  section_effect = c(-3.2, -0.9, -5.0, 1.4, 4.0, -1.9, 5.8, 2.0, 4.9, 7.2, 8.4, 4.5),
  volatility = c(1.4, 1.0, 1.8, 1.2, 1.1, 1.6, 1.0, 1.5, 1.3, 1.2, 1.0, 1.6),
  stringsAsFactors = FALSE
)

skills_by_course <- list(
  "Algebra 1" = c("Functions", "Linear Models", "Equations", "Data"),
  "Geometry" = c("Proof", "Similarity", "Circles", "Coordinate Geometry"),
  "Precalculus" = c("Functions", "Trigonometry", "Modeling", "Rates"),
  "AP Statistics" = c("Inference", "Probability", "Regression", "Experimental Design")
)

completion_by_period <- c(0.62, 0.76, 0.80, 0.87, 0.89, 0.94, 0.95, 0.97)
true_zero_by_period <- c(0.035, 0.025, 0.022, 0.018, 0.014, 0.012, 0.010, 0.008)
score_lift_by_period <- c(-4.0, 2.8, -0.8, 6.7, 1.5, 9.8, 4.2, 12.5)
mastery_by_period <- c(58, 60, 62, 64, 66, 68, 70, 72)

parse_args <- function(args) {
  parsed <- list(
    bootstrap_csv = NA_character_,
    score_column = "9",
    out_dir = "data/synthetic",
    seed = as.character(default_seed)
  )
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) {
      stop(sprintf("Unexpected argument: %s", key), call. = FALSE)
    }
    if (i == length(args)) {
      stop(sprintf("Missing value for argument: %s", key), call. = FALSE)
    }
    value <- args[[i + 1L]]
    name <- sub("^--", "", key)
    name <- gsub("-", "_", name)
    parsed[[name]] <- value
    i <- i + 2L
  }
  parsed$seed <- as.integer(parsed$seed)
  parsed
}

parse_number <- function(x) {
  text <- gsub("[,%]", "", trimws(as.character(x)))
  suppressWarnings(as.numeric(text))
}

default_bootstrap_scores <- function() {
  # Public-safe calibration fallback. This shape approximates a moderately
  # dispersed assessment distribution with early non-participation zeros.
  nonzero <- pmin(100, pmax(1, round(rnorm(211L, mean = 57, sd = 21), 1)))
  c(rep(0, 75L), nonzero)
}

read_bootstrap_scores <- function(path, score_column) {
  if (is.na(path) || !nzchar(path)) {
    return(default_bootstrap_scores())
  }
  if (!file.exists(path)) {
    stop(sprintf("Bootstrap CSV not found: %s", path), call. = FALSE)
  }
  data <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  column_index <- suppressWarnings(as.integer(score_column))
  if (!is.na(column_index)) {
    if (column_index < 1L || column_index > ncol(data)) {
      stop("score-column index is out of range.", call. = FALSE)
    }
    values <- data[[column_index]]
  } else {
    if (!score_column %in% names(data)) {
      stop(sprintf("score-column not found: %s", score_column), call. = FALSE)
    }
    values <- data[[score_column]]
  }
  scores <- parse_number(values)
  scores <- scores[!is.na(scores)]
  if (!length(scores)) {
    stop("No numeric bootstrap scores found.", call. = FALSE)
  }
  scores
}

clamp <- function(x, low, high) {
  pmin(high, pmax(low, x))
}

safe_mean <- function(x) {
  if (!length(x)) {
    return(0)
  }
  mean(x)
}

skill_column_name <- function(skill_name) {
  paste0("skill_", gsub("[^A-Za-z0-9]+", "_", skill_name))
}

build_section_metadata <- function() {
  rows <- list()
  all_skill_cols <- unique(unlist(lapply(skills_by_course, skill_column_name), use.names = FALSE))
  for (idx in seq_len(nrow(section_blueprints))) {
    section <- section_blueprints[idx, ]
    skill_names <- skills_by_course[[section$course]]
    skill_values <- round(runif(length(skill_names), -6.5, 6.5) + section$section_effect * 0.28, 1)
    row <- as.list(section)
    for (skill_col in all_skill_cols) {
      row[[skill_col]] <- NA_real_
    }
    for (skill_idx in seq_along(skill_names)) {
      row[[skill_column_name(skill_names[[skill_idx]])]] <- skill_values[[skill_idx]]
    }
    rows[[idx]] <- row
  }
  as.data.frame(do.call(rbind, lapply(rows, as.data.frame)), stringsAsFactors = FALSE)
}

generate_student_records <- function(bootstrap_scores, section_metadata) {
  nonzero_scores <- bootstrap_scores[bootstrap_scores > 0]
  if (!length(nonzero_scores)) {
    nonzero_scores <- default_bootstrap_scores()
    nonzero_scores <- nonzero_scores[nonzero_scores > 0]
  }
  raw_pool <- clamp(round(nonzero_scores * item_count / 100), 1, item_count)
  records <- list()
  cursor <- 1L

  for (section_index in seq_len(nrow(section_metadata))) {
    section <- section_metadata[section_index, ]
    sid <- section$id
    base_n <- as.integer(section$students)
    section_effect <- as.numeric(section$section_effect)
    volatility <- as.numeric(section$volatility)
    student_ids <- sprintf("%s-student-%02d", sid, seq_len(base_n + 6L))
    latent_ability <- rnorm(length(student_ids), mean = section_effect, sd = 8.5)
    names(latent_ability) <- student_ids

    for (period_index in seq_len(nrow(periods))) {
      period <- periods[period_index, ]
      enrollment <- max(
        14L,
        round(base_n + sample(-3:2, 1L) + sin((section_index + 2L) * (period_index + 1L)) * 1.8)
      )
      enrolled_ids <- student_ids[seq_len(min(enrollment, length(student_ids)))]
      completion_rate <- completion_by_period[[period_index]] +
        section_effect * 0.0025 +
        runif(1L, -0.085, 0.055) +
        ifelse(period$season == "Spring", 0.025, 0)
      completion_rate <- clamp(completion_rate, 0.42, 0.995)
      completed_count <- max(2L, min(length(enrolled_ids), round(length(enrolled_ids) * completion_rate)))
      completed_ids <- sample(enrolled_ids, completed_count)

      for (student_id in enrolled_ids) {
        completed <- student_id %in% completed_ids
        raw_score <- 0L
        score <- 0
        if (completed) {
          if (runif(1L) >= true_zero_by_period[[period_index]]) {
            base_raw <- sample(raw_pool, 1L)
            ability_shift <- latent_ability[[student_id]] * item_count / 100
            period_shift <- score_lift_by_period[[period_index]] * item_count / 100
            section_shift <- section_effect * item_count / 100
            noise <- rnorm(1L, mean = 0, sd = 2.6 + volatility)
            seasonal <- if (period$season == "Spring") sample(c(0, 0, 1, 1, 2), 1L) else sample(c(-1, 0, 0, 1), 1L)
            raw_score <- as.integer(clamp(round(base_raw + ability_shift + period_shift + section_shift + noise + seasonal), 1, item_count))
          }
          score <- raw_score * 100 / item_count
        }
        records[[cursor]] <- data.frame(
          id = sprintf("%s-%s", student_id, period$id),
          studentId = student_id,
          sectionId = sid,
          course = section$course,
          grade = section$grade,
          teacher = section$teacher,
          section = section$section,
          periodId = period$id,
          periodLabel = period$label,
          year = period$year,
          season = period$season,
          order = period$order,
          completed = completed,
          rawScore = raw_score,
          itemCount = item_count,
          score = round(score, 1),
          stringsAsFactors = FALSE
        )
        cursor <- cursor + 1L
      }
    }
  }

  do.call(rbind, records)
}

skill_columns <- function(data) {
  grep("^skill_", names(data), value = TRUE)
}

summarize_section_periods <- function(student_records, section_metadata) {
  rows <- list()
  cursor <- 1L
  skill_cols <- skill_columns(section_metadata)

  for (section_index in seq_len(nrow(section_metadata))) {
    section <- section_metadata[section_index, ]
    section_rows <- student_records[student_records$sectionId == section$id, ]
    first_score <- NA_real_
    for (period_index in seq_len(nrow(periods))) {
      period <- periods[period_index, ]
      period_rows <- section_rows[section_rows$periodId == period$id, ]
      completed_rows <- period_rows[period_rows$completed, ]
      score <- safe_mean(completed_rows$score)
      if (is.na(first_score)) {
        first_score <- score
      }
      mastery <- mastery_by_period[[period$order]]
      summary_row <- data.frame(
        id = sprintf("%s-%s", section$id, period$id),
        sectionId = section$id,
        course = section$course,
        grade = section$grade,
        teacher = section$teacher,
        section = section$section,
        periodId = period$id,
        periodLabel = period$label,
        year = period$year,
        season = period$season,
        order = period$order,
        students = nrow(period_rows),
        completed = nrow(completed_rows),
        notCompleted = nrow(period_rows) - nrow(completed_rows),
        trueZeroScores = sum(completed_rows$rawScore == 0),
        score = round(score, 1),
        proficiency = ifelse(nrow(completed_rows), round(100 * mean(completed_rows$score >= mastery), 1), 0),
        completion = ifelse(nrow(period_rows), round(100 * nrow(completed_rows) / nrow(period_rows), 1), 0),
        growth = round(score - first_score, 1),
        rawMean = round(safe_mean(completed_rows$rawScore), 2),
        itemCount = item_count,
        stringsAsFactors = FALSE
      )
      for (skill_col in skill_cols) {
        summary_row[[skill_col]] <- section[[skill_col]]
      }
      rows[[cursor]] <- summary_row
      cursor <- cursor + 1L
    }
  }

  do.call(rbind, rows)
}

finalize_section_metadata <- function(section_metadata, section_period_summary) {
  section_metadata$baseline <- NA_real_
  section_metadata$growth <- NA_real_
  section_metadata$springLift <- NA_real_
  for (idx in seq_len(nrow(section_metadata))) {
    sid <- section_metadata$id[[idx]]
    rows <- section_period_summary[section_period_summary$sectionId == sid, ]
    rows <- rows[order(rows$order), ]
    spring_rows <- rows[rows$season == "Spring", ]
    fall_rows <- rows[rows$season == "Fall", ]
    section_metadata$baseline[[idx]] <- round(rows$score[[1]], 1)
    section_metadata$growth[[idx]] <- round((rows$score[[nrow(rows)]] - rows$score[[1]]) / 3.5, 2)
    section_metadata$springLift[[idx]] <- round(mean(spring_rows$score) - mean(fall_rows$score), 2)
  }
  section_metadata
}

write_outputs <- function(out_dir, student_records, section_summary, section_metadata, bootstrap_scores) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(student_records, file.path(out_dir, "student_level_assessment.csv"), row.names = FALSE)
  write.csv(section_summary, file.path(out_dir, "section_period_summary.csv"), row.names = FALSE)
  write.csv(section_metadata, file.path(out_dir, "section_metadata.csv"), row.names = FALSE)
  calibration <- data.frame(
    metric = c("bootstrap_scores", "nonzero_scores", "zero_scores", "synthetic_item_count"),
    value = c(
      length(bootstrap_scores),
      sum(bootstrap_scores > 0),
      sum(bootstrap_scores == 0),
      item_count
    )
  )
  write.csv(calibration, file.path(out_dir, "calibration_summary.csv"), row.names = FALSE)
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  set.seed(args$seed)
  bootstrap_scores <- read_bootstrap_scores(args$bootstrap_csv, args$score_column)
  section_metadata <- build_section_metadata()
  student_records <- generate_student_records(bootstrap_scores, section_metadata)
  section_summary <- summarize_section_periods(student_records, section_metadata)
  section_metadata <- finalize_section_metadata(section_metadata, section_summary)
  write_outputs(args$out_dir, student_records, section_summary, section_metadata, bootstrap_scores)
  message(sprintf("wrote synthetic CSV outputs to %s", args$out_dir))
  message(sprintf("synthetic student-period records: %s", nrow(student_records)))
  message(sprintf("section-period summary records: %s", nrow(section_summary)))
}

main()
