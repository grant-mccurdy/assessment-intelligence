# R Analysis Pipeline

GitHub Pages is static, so the browser dashboard cannot run R server-side. This
project uses R as the build and analysis layer:

```text
R synthetic data generation
-> R growth and completion modeling
-> R Markdown modeling report
-> dashboard-ready JSON export
-> static JavaScript dashboard runtime
```

This architecture showcases statistical modeling while keeping the deployed site
fast, static, and public-safe.

## Files

```text
analysis/
  generate_synthetic_assessment_data.R
  model_growth.R
  model_completion.R
  export_dashboard_json.R
  run_pipeline.R
data/synthetic/
  student_level_assessment.csv
  section_period_summary.csv
  section_metadata.csv
  calibration_summary.csv
  assessment-dashboard.json
reports/
  assessment_modeling_report.Rmd
```

## Run

From `assessment-intelligence/`:

```bash
Rscript analysis/run_pipeline.R
```

To calibrate from a private local export without publishing the export:

```bash
Rscript analysis/run_pipeline.R \
  --bootstrap-csv data/private/private_assessment_export.csv \
  --score-column 9
```

To sync the exported JSON into the GitHub Pages dashboard after the R pipeline
runs:

```bash
Rscript analysis/export_dashboard_json.R \
  --pages-output ../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json
```

## Recommended R Packages

Core package:

- `jsonlite` for dashboard JSON export

Useful reporting/modeling packages:

- `tidyverse` for data wrangling
- `ggplot2` for diagnostic/static plots
- `broom` for clean model summaries
- `lme4` or `nlme` for mixed models
- `rpart` for interpretable decision-tree examples
- `rmarkdown` or Quarto for reproducible reports

The first implementation keeps most scripts base-R compatible so the workflow
remains easy to inspect. `jsonlite` is required only for JSON export.

