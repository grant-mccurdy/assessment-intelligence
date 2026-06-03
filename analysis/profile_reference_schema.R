#!/usr/bin/env Rscript

source("analysis/gradebook_reconstruction_lib.R")

args <- parse_cli(
  commandArgs(trailingOnly = TRUE),
  defaults = list(
    private_profile_out = "data/private/reference_gradebook_schema_profile.csv",
    public_report_out = "reports/gradebook_reference_schema_public.md"
  ),
  required = c("reference_gradebook")
)

gradebook <- read_gradebook(args$reference_gradebook)
profile <- profile_columns(gradebook)

dir.create(dirname(args$private_profile_out), recursive = TRUE, showWarnings = FALSE)
write.csv(profile, args$private_profile_out, row.names = FALSE)

role_summary <- aggregate(
  column_index ~ role + mostly_numeric,
  data = profile,
  FUN = length
)
names(role_summary)[names(role_summary) == "column_index"] <- "columns"

public_rows <- data.frame(
  Metric = c(
    "Rows",
    "Columns",
    "Assignment-like columns",
    "Mostly numeric columns",
    "Blank-heavy columns"
  ),
  Value = c(
    nrow(gradebook),
    ncol(gradebook),
    sum(profile$role == "assignment"),
    sum(profile$mostly_numeric),
    sum(profile$blank_rate >= 0.25)
  ),
  stringsAsFactors = FALSE
)

report <- c(
  "# Public-Safe Gradebook Schema Profile",
  "",
  "This report summarizes schema shape only. Private column names, assignment titles, rows, and values are not printed.",
  "",
  "## Summary",
  "",
  write_markdown_table(public_rows),
  "",
  "## Role Summary",
  "",
  write_markdown_table(role_summary),
  "",
  "Private detailed profile written to an ignored local path:",
  "",
  sprintf("`%s`", args$private_profile_out)
)

dir.create(dirname(args$public_report_out), recursive = TRUE, showWarnings = FALSE)
writeLines(report, args$public_report_out)
message(sprintf("wrote %s", args$public_report_out))
message(sprintf("wrote private schema profile to %s", args$private_profile_out))
