# Gradebook Reconstruction Workflow

The private repository stores protected reference artifacts. The public
`assessment-intelligence` repository demonstrates the R workflow that learns
schema, data types, missingness, and distribution shape from those references
and reconstructs a public-safe synthetic gradebook.

```text
private reference gradebook
-> public R schema profiler
-> public R latent-trait synthetic gradebook generator
-> public long-form student-score reconstruction
-> public R validation report
-> public synthetic assessment analytics
```

## Private Input

The reference file stays private. Do not hard-code or publish the concrete local
path. Use a shell variable or local config:

```text
REFERENCE_GRADEBOOK="<private reference gradebook path>"
```

Do not copy it into the public repo.

## Public Scripts

```text
analysis/profile_reference_schema.R
analysis/generate_synthetic_gradebook.R
analysis/validate_synthetic_gradebook.R
```

The generator now creates three public-safe artifacts:

```text
data/synthetic/synthetic_gradebook.csv
data/synthetic/synthetic_student_scores_long.csv
data/synthetic/synthetic_assignment_metadata.csv
```

The wide gradebook preserves the Canvas-style export shape. The long-form score
table is designed for analytics, modeling, dashboards, and reporting.

### Profile Schema

```bash
Rscript analysis/profile_reference_schema.R \
  --reference-gradebook "$REFERENCE_GRADEBOOK"
```

This writes:

```text
reports/gradebook_reference_schema_public.md
data/private/reference_gradebook_schema_profile.csv
```

The public report summarizes shape only. The detailed profile is written under
`data/private/`, which is ignored.

### Generate Synthetic Gradebook

```bash
Rscript analysis/generate_synthetic_gradebook.R \
  --reference-gradebook "$REFERENCE_GRADEBOOK" \
  --output data/synthetic/synthetic_gradebook.csv
```

Default public-safe behavior:

- preserves Canvas-standard fields
- preserves column count and column order
- preserves field data types and score-like distributions
- preserves missingness behavior
- rank-maps synthetic scores onto reference assignment quantiles
- models completion separately from low performance
- simulates correlated student ability, engagement, growth, and submission-risk
  factors
- emits a long-form student-assignment score table for analytics
- emits public-safe assignment metadata with sequence, family, and skill-domain
  labels
- generates fake student names, IDs, SIS IDs, logins, and sections
- sanitizes assignment-like column labels as `Assignment NN`

Private-only option:

```bash
Rscript analysis/generate_synthetic_gradebook.R \
  --reference-gradebook "$REFERENCE_GRADEBOOK" \
  --output data/private/synthetic_gradebook_exact_columns.csv \
  --preserve-reference-column-names \
  --preserve-section-labels
```

Use exact-column mode only for private local validation. Do not publish exact
assignment names or section labels unless they are explicitly public-safe.

### Validate Synthetic Gradebook

```bash
Rscript analysis/validate_synthetic_gradebook.R \
  --reference-gradebook "$REFERENCE_GRADEBOOK" \
  --synthetic-gradebook data/synthetic/synthetic_gradebook.csv
```

The validation report checks:

- row and column shape
- numeric column shape
- identity-value overlap
- missingness similarity
- assignment mean and spread fidelity
- long-form analytics schema
- assignment metadata row count
- role counts

### Full Workflow

From `assessment-intelligence/`:

```bash
export REFERENCE_GRADEBOOK="<private reference gradebook path>"
make gradebook-workflow
```

This runs profile, synthesis, and validation as one reproducible R workflow.

To render the portfolio-facing R Markdown report from the synthetic outputs:

```bash
make render-gradebook-report-html
make render-gradebook-report-pdf
```

## Sophisticated R Techniques Featured

The workflow is intended to be visible as a statistics/data-engineering artifact,
not just a demo data generator:

- schema inference from a protected Canvas export
- role classification for standard LMS fields and assignment-like columns
- empirical distribution profiling by assignment column
- rank-based quantile mapping to preserve realistic score shapes without copying
  rows
- correlated latent traits for ability, engagement, growth, and submission risk
- missingness modeled separately from true score performance
- wide-to-long reconstruction for analysis-ready student-assignment records
- automated public-safety validation and distribution-fidelity reporting

## Portfolio Framing

> The private repository stores protected reference artifacts; the public
> repository demonstrates the reproducible R workflow that learns schema,
> missingness, score distribution, latent participation structure, and
> assignment-level shape from private references, then reconstructs public-safe
> synthetic datasets for assessment analytics.
