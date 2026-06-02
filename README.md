# Assessment Intelligence

Public-safe assessment analytics and reporting project for mathematics programs.

This repository is intended to demonstrate how assessment systems can be designed, processed, analyzed, and reported using synthetic data. The goal is to show reproducible assessment intelligence workflows without exposing real students, grades, submissions, school records, or private LMS data.

## What This Project Demonstrates

- Assessment system design
- Synthetic assessment data generation
- Real-to-synthetic distribution bootstrapping with public-safe outputs
- Privacy and schema validation before release
- Reproducible data processing
- Department, school, course, class, teacher, and student-level reporting views
- Decision-support dashboards and written reports
- Privacy-aware reporting architecture

## Planned Structure

```text
assessment-intelligence/
├── analysis/
│   ├── generate_synthetic_assessment_data.R
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
│   ├── reporting-architecture.md
│   ├── privacy-model.md
│   └── openai-assisted-reporting.md
├── screenshots/
└── README.md
```

## Synthetic Data Workflow

The central feature is a privacy-aware transformation pipeline:

```text
private assessment export
-> private profiling and calibration
-> synthetic student/section/time-series generator
-> validation report
-> public dashboard and reports
```

The public project should show how useful analytics can be preserved without
publishing real students, rosters, school-private exports, or LMS records.

## R Analysis Build Layer

The dashboard frontend should remain static JavaScript for GitHub Pages. R is
used before deployment to generate synthetic data, fit growth/completion models,
render a modeling report, and export dashboard-ready JSON:

```bash
Rscript analysis/run_pipeline.R
```

The key portfolio message is:

> The dashboard is powered by a reproducible R statistical modeling pipeline
> that generates synthetic assessment data, estimates growth and completion
> patterns, and exports dashboard-ready JSON for a static web frontend.

Run the current validator against the GitHub Pages dashboard dataset:

```bash
python3 scripts/validate_synthetic_privacy.py \
  --input ../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json
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

Public-safe scaffolding in progress. Synthetic-data methodology, privacy model,
OpenAI-assisted reporting notes, validation script, and dry-run-first memo
generator are now staged.
