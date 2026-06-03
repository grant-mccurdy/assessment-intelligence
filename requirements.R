packages <- c(
  "broom",
  "caret",
  "data.table",
  "ggplot2",
  "httpgd",
  "IRkernel",
  "janitor",
  "jsonlite",
  "knitr",
  "languageserver",
  "lme4",
  "lubridate",
  "nlme",
  "quarto",
  "readr",
  "readxl",
  "rmarkdown",
  "rpart",
  "tidyverse"
)

installed <- rownames(installed.packages())
missing <- setdiff(packages, installed)

if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

cat("R package setup complete. Installed packages checked:", length(packages), "\n")
