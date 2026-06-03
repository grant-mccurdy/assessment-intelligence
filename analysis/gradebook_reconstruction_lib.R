# Shared helpers for public-safe gradebook reconstruction workflows.

parse_cli <- function(args, defaults = list(), required = character()) {
  parsed <- defaults
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    if (!startsWith(key, "--")) {
      stop(sprintf("Unexpected argument: %s", key), call. = FALSE)
    }
    name <- gsub("-", "_", sub("^--", "", key))
    if (name %in% c("preserve_reference_column_names", "preserve_section_labels")) {
      parsed[[name]] <- TRUE
      i <- i + 1L
    } else {
      if (i == length(args)) {
        stop(sprintf("Missing value for argument: %s", key), call. = FALSE)
      }
      parsed[[name]] <- args[[i + 1L]]
      i <- i + 2L
    }
  }
  for (name in required) {
    if (is.null(parsed[[name]]) || is.na(parsed[[name]]) || !nzchar(as.character(parsed[[name]]))) {
      stop(sprintf("Missing required argument: --%s", gsub("_", "-", name)), call. = FALSE)
    }
  }
  parsed
}

read_gradebook <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("Reference gradebook not found: %s", path), call. = FALSE)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

standard_role <- function(name) {
  low <- tolower(trimws(name))
  exact <- list(
    student = "student",
    id = "id",
    sis_user_id = "sis user id",
    sis_login_id = "sis login id",
    section = "section",
    current_score = "current score",
    final_score = "final score",
    unposted_final_score = "unposted final score",
    current_grade = "current grade",
    final_grade = "final grade"
  )
  for (role in names(exact)) {
    if (low == exact[[role]]) {
      return(role)
    }
  }
  "assignment"
}

numeric_values <- function(values) {
  text <- gsub("[,%]", "", trimws(as.character(values)))
  suppressWarnings(as.numeric(text))
}

is_numeric_like <- function(values, threshold = 0.85) {
  nonblank <- values[!is.na(values) & nzchar(trimws(as.character(values)))]
  if (!length(nonblank)) {
    return(FALSE)
  }
  parsed <- numeric_values(nonblank)
  mean(!is.na(parsed)) >= threshold
}

profile_columns <- function(data) {
  rows <- list()
  for (idx in seq_along(names(data))) {
    name <- names(data)[[idx]]
    values <- data[[idx]]
    nonblank <- values[!is.na(values) & nzchar(trimws(as.character(values)))]
    parsed <- numeric_values(nonblank)
    numeric_nonblank <- parsed[!is.na(parsed)]
    rows[[idx]] <- data.frame(
      column_index = idx,
      column_name = name,
      role = standard_role(name),
      mostly_numeric = is_numeric_like(values),
      nonblank_count = length(nonblank),
      blank_rate = round(mean(is.na(values) | !nzchar(trimws(as.character(values)))), 4),
      mean = ifelse(length(numeric_nonblank), mean(numeric_nonblank), NA_real_),
      sd = ifelse(length(numeric_nonblank) > 1L, sd(numeric_nonblank), 0),
      min = ifelse(length(numeric_nonblank), min(numeric_nonblank), NA_real_),
      max = ifelse(length(numeric_nonblank), max(numeric_nonblank), NA_real_),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

public_column_label <- function(profile_row) {
  if (profile_row$role == "assignment") {
    return(sprintf("Assignment %02d", profile_row$column_index))
  }
  profile_row$column_name
}

grade_from_score <- function(score) {
  if (is.na(score)) {
    return("")
  }
  if (score >= 93) return("A")
  if (score >= 90) return("A-")
  if (score >= 87) return("B+")
  if (score >= 83) return("B")
  if (score >= 80) return("B-")
  if (score >= 77) return("C+")
  if (score >= 73) return("C")
  if (score >= 70) return("C-")
  if (score >= 67) return("D+")
  if (score >= 63) return("D")
  if (score >= 60) return("D-")
  "F"
}

fake_section_labels <- function(reference_sections, n) {
  observed <- reference_sections[!is.na(reference_sections) & nzchar(trimws(reference_sections))]
  if (!length(observed)) {
    return(rep("Section A", n))
  }
  counts <- sort(table(observed), decreasing = TRUE)
  labels <- sprintf("Section %s", LETTERS[seq_along(counts)])
  sample(labels, n, replace = TRUE, prob = as.numeric(counts))
}

write_markdown_table <- function(rows) {
  if (!nrow(rows)) {
    return("No rows.")
  }
  header <- paste(names(rows), collapse = " | ")
  rule <- paste(rep("---", ncol(rows)), collapse = " | ")
  body <- apply(rows, 1, function(row) paste(as.character(row), collapse = " | "))
  paste(c(header, rule, body), collapse = "\n")
}
