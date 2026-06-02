#!/usr/bin/env Rscript

# Run the public-safe R assessment build pipeline.

run_step <- function(script, args = character()) {
  command <- c(script, args)
  message(sprintf("running Rscript %s", paste(command, collapse = " ")))
  status <- system2("Rscript", command)
  if (!identical(status, 0L)) {
    stop(sprintf("Pipeline step failed: %s", script), call. = FALSE)
  }
}

args <- commandArgs(trailingOnly = TRUE)
extra <- character()
if (length(args)) {
  extra <- args
}

run_step("analysis/generate_synthetic_assessment_data.R", extra)
run_step("analysis/model_growth.R")
run_step("analysis/model_completion.R")
run_step("analysis/export_dashboard_json.R")

message("R assessment pipeline complete.")
