# Assessment Intelligence

SQL/R/Python analytics dashboard and reporting project with public-safe data, validation checks, diagnostics, and decision-support outputs.

This repository is the main analytics product in the portfolio. It demonstrates how messy operating records can be transformed into reliable SQL extracts, dashboard-ready data, reproducible reports, model diagnostics, and stakeholder-facing interpretation. The education assessment domain is the case study; the transferable work is the analytics pattern.

Synthetic data is used so the dashboard and reports can be public without exposing real students, grades, submissions, school records, or private LMS data.

## What This Project Demonstrates

- Interactive dashboard design over SQL-shaped extract data
- SQL-backed extract design for performance, growth, completion, reconciliation, and readiness views
- R/Python reporting workflows with validation-backed outputs
- Data-quality and privacy checks before public release
- Reproducible data processing and dashboard artifact export
- Segment-level reporting views for decision support
- Written reports, memos, and analyst-facing interpretation
- Synthetic assessment data generation as the public-safety foundation
- Real-to-synthetic distribution bootstrapping with public-safe outputs
- Advanced R gradebook reconstruction using private-reference schema and distribution profiling
- SQL-backed extracts from the `education-data-simulation-engine` DuckDB warehouse
- Privacy-aware reporting architecture

## Portfolio First Read

Start with the hosted dashboard and reporting artifacts:

- GitHub Pages dashboard: `https://grant-mccurdy.github.io/dashboard/assessment.html`
- Portfolio brief: `https://grant-mccurdy.github.io/projects/assessment-intelligence.html`
- Rendered R report mirrored on the portfolio site: `https://grant-mccurdy.github.io/artifacts/assessment-intelligence/gradebook_synthesis_report.html`

Then inspect the synthetic data foundation only if you want to review how the public-safe records and warehouse extracts are generated.

## Planned Structure

```text
assessment-intelligence/
├── analysis/
│   ├── generate_synthetic_assessment_data.R
│   ├── profile_reference_schema.R
│   ├── generate_synthetic_gradebook.R
│   ├── validate_synthetic_gradebook.R
│   ├── model_growth.R
│   ├── model_completion.R
│   ├── export_dashboard_json.R
│   └── run_pipeline.R
├── dashboard/
├── data/
│   └── synthetic/
├── reports/
│   └── assessment_modeling_report.Rmd
├── notebooks/
├── scripts/
│   ├── validate_synthetic_privacy.py
│   └── generate_ai_assessment_memo.py
├── docs/
│   ├── assessment-design.md
│   ├── synthetic-data-methodology.md
│   ├── r-analysis-pipeline.md
│   ├── gradebook-reconstruction-workflow.md
│   ├── reporting-artifact-philosophy.md
│   ├── reporting-architecture.md
│   ├── privacy-model.md
│   └── openai-assisted-reporting.md
├── screenshots/
└── README.md
```

## Data Privacy And Synthetic Foundation

The public dashboard is backed by a privacy-aware transformation pipeline:

```text
private assessment export
-> private profiling and calibration
-> synthetic student/section/time-series generator
-> validation report
-> public dashboard and reports
```

The public project shows how useful analytics can be preserved without
publishing real students, rosters, school-private exports, or LMS records. The
synthetic data work supports the dashboard and reports; it is not the main
product surface.

Reporting artifacts follow a recommendation-first statistical report philosophy:
answer the leadership question, audit the data, show the model journey, present
checks and sensitivity, then close with a decision-ready bottom line.

Gradebook reconstruction is public workflow, private data:

```text
private reference gradebook
-> public R reconstruction workflow
-> synthetic Canvas-style gradebook
-> long-form student-score analytics dataset
-> assignment metadata and validation report
-> public-safe analytics and reporting artifacts
```

The private reference artifacts remain in a separate private local repository;
this repo contains the reproducible R workflow and public-safe outputs.

## R Analysis Build Layer

The dashboard frontend should remain static JavaScript for GitHub Pages. R is
used before deployment to generate synthetic data, fit growth/completion models,
render a modeling report, and export dashboard-ready JSON:

```bash
Rscript analysis/run_pipeline.R
```

Build a synthetic gradebook from a private reference artifact:

```bash
REFERENCE_GRADEBOOK="<private reference gradebook path>"
make gradebook-workflow
```

This R workflow profiles the private gradebook shape, synthesizes correlated
student score patterns, rank-maps scores onto reference assignment quantiles,
models missingness separately from performance, and exports both a wide
Canvas-style gradebook and long-form student-assignment score records.

Render the synthesis report:

```bash
make render-gradebook-report-html
make render-gradebook-report-pdf
```

## Evidence Packet

The current public proof packet for the gradebook synthesis workflow is:

```text
data/synthetic/synthetic_gradebook.csv
data/synthetic/synthetic_student_scores_long.csv
data/synthetic/synthetic_assignment_metadata.csv
reports/advanced_synthetic_gradebook_synthesis.md
reports/gradebook_reference_schema_public.md
reports/gradebook_reconstruction_validation.md
reports/gradebook_synthesis_report.html
reports/gradebook_synthesis_report.pdf
```

Current validation summary:

- 287 synthetic gradebook rows and 39 columns.
- 8,036 long-form synthetic student-assignment records.
- 28 public-safe assignment metadata rows.
- Zero identity overlap in the wide gradebook and long analytics output.
- Numeric shape, row count, column count, missingness similarity, and assignment
  mean fidelity checks pass.

Rebuild the evidence packet from a private local reference path:

```bash
REFERENCE_GRADEBOOK="<private reference gradebook path>"
make gradebook-workflow
make render-gradebook-report-html
make render-gradebook-report-pdf
```

The GitHub Pages portfolio mirrors the public-safe report artifacts under:

```text
artifacts/assessment-intelligence/
```

The key portfolio message is:

> The dashboard is powered by a reproducible R statistical modeling pipeline
> that generates synthetic assessment data, estimates growth and completion
> patterns, and exports dashboard-ready JSON for a static web frontend.

## Visualization Catalog

The repository includes a small, decision-question-oriented visualization
catalog at [docs/plot_catalog.qmd](docs/plot_catalog.qmd). The first release
covers three public-safe assessment analytics plots:

- Raincloud plot for comparing full score distributions.
- Hexbin plot for dense readiness-growth relationships.
- Calibration plot for evaluating predicted mastery probabilities.

The catalog uses synthetic response events and model outputs only. Rebuild the
catalog datasets and rendered PNGs with:

```bash
Rscript --vanilla R/plots/generate_plot_catalog_data.R
Rscript --vanilla R/plots/render_plot_catalog_plots.R
quarto render docs/plot_catalog.qmd --to html
```

Rendered plot images are written to `outputs/plots/`, and the synthetic catalog
CSV files are written to `data/synthetic/`.

## SQL Warehouse Integration

The sibling `education-data-simulation-engine` project can generate a DuckDB warehouse from synthetic Canvas-like artifacts, assessment gradebooks, roster records, and star-schema marts.

This project can query that warehouse and export analysis-ready assessment extracts:

```bash
cd ../education-data-simulation-engine
make analytics-install
make warehouse

cd ../assessment-intelligence
make analytics-install
make synthetic-warehouse-extract
```

The extract target writes SQL-backed public-safe datasets to:

```text
data/external/education-data-simulation-engine/
```

and writes a summary report:

```text
reports/sql_warehouse_assessment_extract.md
```

Generate the analyst-facing SQL warehouse report:

```bash
make sql-warehouse-report
```

This writes:

```text
reports/sql_warehouse_assessment_report.md
```

Build and sync the GitHub Pages dashboard artifact from the same SQL extract
set:

```bash
make dashboard-sync
```

This writes `data/synthetic/assessment-dashboard.json` locally and syncs the
static Pages copy at
`../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json`.

See [docs/synthetic-warehouse-integration.md](docs/synthetic-warehouse-integration.md)
for the build flow and [docs/sql-extract-data-dictionary.md](docs/sql-extract-data-dictionary.md)
for the extract contract.

Run the optional hosted Supabase extraction after local credentials are
available in the shared local `.env` file:

```bash
SYNTHETIC_EDUCATION_SUPABASE_URL=...
SYNTHETIC_EDUCATION_SUPABASE_PUBLISHABLE_KEY=...
make supabase-extract
make supabase-report
```

The hosted extract uses the Supabase Data API against selected public read-only
views in the `education-data-simulation-engine` project. It writes hosted outputs to:

```text
data/external/education-data-simulation-engine-supabase/
reports/supabase_assessment_extract.md
reports/supabase_assessment_report.md
```

DuckDB remains the default reproducible local integration. Supabase is the
optional hosted serving layer for public-safe synthetic analytics views. The
hosted extract currently includes `student_readiness_extract.csv`; base `lms`
and `analytics` tables remain outside the public API contract.

Generate an OpenAI-assisted post-extract review without making a network call:

```bash
make ai-extract-review
```

This writes a prompt preview, structured review JSON, and Markdown review:

```text
reports/ai-extract-review-prompt.md
reports/ai-extract-review.json
reports/ai-extract-review.md
```

The API-enabled version is explicit and reads only OpenAI allowlisted variables
from the shared local env file:

```bash
make ai-extract-review-api
```

OpenAI is used only as an advisory reporting layer over synthetic aggregate
artifacts; it does not query Supabase directly or transform extract CSVs.

Clean regenerated public report artifacts without touching private directories:

```bash
make clean-generated
```

Run the current validator against the GitHub Pages dashboard dataset:

```bash
python3 scripts/validate_synthetic_privacy.py \
  --input ../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json
```

Refresh the static dashboard artifact consumed by GitHub Pages:

```bash
make dashboard-sync
```

Generate a dry-run leadership memo from the same synthetic data:

```bash
python3 scripts/generate_ai_assessment_memo.py
```

This writes a prompt preview and sample memo without calling the OpenAI API. To
make a real API call, use `--call-api` after confirming the input is synthetic
and public-safe.

## Public Data Model

All examples should use synthetic data. Public examples may include fake students, fake teachers, fake course sections, fake assessment items, and fake performance results.

Public examples must not include real student names, emails, IDs, grades, rosters, submissions, Canvas exports, or school-private reporting artifacts.

## Portfolio Framing

This is not a Canvas reporting project. Canvas may be one possible data source or adapter, but the public framing is assessment intelligence: assessment design, analysis, reporting, and decision support.

## Status

Active public-safe build. Synthetic-data methodology, privacy model,
OpenAI-assisted reporting notes, dashboard privacy validation, dry-run-first
memo generation, R gradebook reconstruction, synthetic gradebook outputs, and
public validation reports are now staged.
