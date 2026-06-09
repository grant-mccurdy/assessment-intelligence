# R Analysis Pipeline

GitHub Pages is static, so browser dashboards cannot run R server-side. This
project keeps R as a modeling and legacy dashboard-export lane:

```text
R synthetic data generation
-> R growth and completion modeling
-> R Markdown modeling report
-> dashboard-ready JSON export for local/modeling demos
```

The gradebook reconstruction workflow is a second R build lane:

```text
private Canvas-style gradebook
-> R schema/profile extraction
-> R latent-trait synthetic gradebook reconstruction
-> wide synthetic gradebook + long student-score table
-> validation and distribution-fidelity report
```

The featured GitHub Pages dashboard is now built from the SQL warehouse extract
contract documented in `docs/synthetic-warehouse-integration.md`; run
`make dashboard-sync` to refresh that public artifact.

Reporting artifacts should follow the companion philosophy in
`docs/reporting-artifact-philosophy.md`: recommendation first, then data audit,
model journey, final method, model checks, sensitivity, and decision-ready
bottom line.

## Files

```text
analysis/
  profile_reference_schema.R
  generate_synthetic_gradebook.R
  validate_synthetic_gradebook.R
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
  synthetic_gradebook.csv
  synthetic_student_scores_long.csv
  synthetic_assignment_metadata.csv
reports/
  assessment_modeling_report.Rmd
  gradebook_synthesis_report.Rmd
  advanced_synthetic_gradebook_synthesis.md
  gradebook_reconstruction_validation.md
```

## Run

From `assessment-intelligence/`:

```bash
Rscript analysis/run_pipeline.R
```

Gradebook reconstruction from a private reference artifact:

```bash
REFERENCE_GRADEBOOK="<private reference gradebook path>"

make gradebook-workflow
```

This emits a Canvas-style wide gradebook, an analytics-ready long score table,
assignment metadata, a synthesis-method report, and a validation report.

Render the gradebook synthesis report after the workflow runs:

```bash
make render-gradebook-report-html
make render-gradebook-report-pdf
```

To calibrate from a private local export without publishing the export:

```bash
Rscript analysis/run_pipeline.R \
  --bootstrap-csv data/private/private_assessment_export.csv \
  --score-column 9
```

Run the SQL-backed dashboard sync for the featured GitHub Pages artifact:

```bash
make dashboard-sync
```

To regenerate the R modeling JSON only, use:

```bash
Rscript analysis/export_dashboard_json.R
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
