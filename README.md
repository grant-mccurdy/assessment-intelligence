# Assessment Intelligence

Stakeholder-facing assessment analytics built from public-safe synthetic data.

## Project Links

- [Open the live assessment dashboard](https://grant-mccurdy.github.io/dashboard/assessment.html)
- [Read the concise portfolio brief](https://grant-mccurdy.github.io/projects/assessment-intelligence.html)
- [Review the reporting case study](https://grant-mccurdy.github.io/case-studies/assessment-reporting.html)
- [Inspect the rendered R synthesis report](https://grant-mccurdy.github.io/artifacts/assessment-intelligence/gradebook_synthesis_report.html)

Assessment Intelligence turns SQL-backed assessment records into an interactive
dashboard, reproducible reports, data-quality checks, and decision notes that
help instructional leaders answer four practical questions:

- Are students improving over time?
- Where are performance or participation signals weakest?
- Which courses or sections warrant closer review?
- Is the underlying data reliable enough to support a decision?

All public artifacts use synthetic students, teachers, sections, assessments,
and outcomes. No real student, school, LMS, personnel, or employer data belongs
in this repository.

The first dashboard view presents current score, growth, completion,
proficiency, distribution, and readiness signals. Ranked decision insights use
a minimum cohort size of 10 so small groups are not elevated as headline
findings.

## What The Project Proves

### Dashboard and stakeholder interpretation

The deployed static dashboard provides browser-side filtering and aggregation,
SVG charts, section detail, and generated decision notes over a public-safe SQL
extract. The dashboard presentation is deployed from the portfolio repository:

- [Dashboard HTML source](https://github.com/grant-mccurdy/grant-mccurdy.github.io/blob/main/dashboard/assessment.html)
- [Dashboard JavaScript source](https://github.com/grant-mccurdy/grant-mccurdy.github.io/blob/main/assets/js/assessment-dashboard.js)
- [Dashboard logic smoke test](https://github.com/grant-mccurdy/grant-mccurdy.github.io/blob/main/scripts/dashboard_logic_smoke.mjs)

This repository owns the assessment extract contract, dashboard-data builder,
statistical workflows, validation, and reporting artifacts. The portfolio repo
owns the shared visual shell used to publish them.

The builder also writes a publication manifest containing the dashboard
SHA-256, builder SHA-256, extract hashes and row counts, and dashboard record
counts. The portfolio site's quality check verifies its deployed JSON against
that manifest, making source drift visible before publication.

### SQL-backed analytics

Five SQL extracts support distinct stakeholder questions:

| Extract | Decision use |
| --- | --- |
| Course-section performance | Compare score, proficiency, completion, and participation signals. |
| Assignment growth | Identify course-level movement using matched observations. |
| Non-participation | Keep missing participation separate from achievement evidence. |
| LMS reconciliation | Confirm roster records are reportable before analysis. |
| Student readiness | Support curated readiness and observed-growth views. |

DuckDB is the reproducible local baseline. Supabase is an optional hosted
serving layer over selected public read-only views; it is not required to
review or rebuild the local demo.

### Reproducible statistical reporting

The R workflows generate synthetic assessment records, fit growth and
completion models, reconstruct a public-safe Canvas-style gradebook, validate
distribution fidelity, and render stakeholder and analyst reports. The Python
workflows extract SQL marts, build dashboard JSON, validate privacy boundaries,
and generate deterministic report artifacts.

## Architecture

```text
education-data-simulation-engine
  synthetic Canvas-style records and DuckDB marts
                |
                v
assessment-intelligence
  SQL extracts -> validation -> analysis -> reports -> dashboard JSON
                |
                v
grant-mccurdy.github.io
  static dashboard presentation and portfolio case study
```

The separation is intentional:

- `education-data-simulation-engine` owns public-safe source simulation.
- `assessment-intelligence` owns assessment analytics and interpretation.
- `grant-mccurdy.github.io` owns the deployed presentation shell.

## Reproduce The SQL Reporting Path

Build the sibling synthetic warehouse:

```bash
cd ../education-data-simulation-engine
make analytics-install
make warehouse
```

Generate the assessment extracts and analyst report:

```bash
cd ../assessment-intelligence
make analytics-install
make sql-warehouse-report
```

Build the dashboard JSON and publication manifest, then sync both portfolio
deployment artifacts:

```bash
make dashboard-sync
```

Run the public dashboard privacy validator:

```bash
make all
```

The validator checks required fields, forbidden identity fields and values,
synthetic ID conventions, percentage bounds, cohort sizes, and disclosure of
the private-to-synthetic boundary.

## Secondary Evidence

The repository also contains deeper proof for technical reviewers:

- `sql/extracts/` and `sql/extracts_postgres/` define the DuckDB and hosted
  extract contracts.
- `scripts/build_sql_dashboard_json.py` converts those extracts into the
  dashboard data model and hash-bound publication manifest.
- `data/published/assessment-dashboard.manifest.json` records the exact SQL
  extracts, builder, counts, and dashboard payload used for publication.
- `reports/sql_warehouse_assessment_report.md` provides a generated analyst
  brief with low-sample ranking safeguards.
- `reports/gradebook_reconstruction_validation.md` documents synthetic
  gradebook fidelity checks.
- `outputs/plots/` contains decision-oriented raincloud, hexbin, and
  calibration examples.
- `docs/privacy-model.md` and `docs/synthetic-data-methodology.md` document the
  public/private boundary and generation method.

Large reproducible local outputs, including the full dashboard JSON and
long-form score table, are intentionally ignored here. Reviewer-facing copies
are either summarized in committed reports or deployed through the portfolio
site.

## Repository Layout

```text
assessment-intelligence/
|-- analysis/          # R generation, modeling, reconstruction, and validation
|-- R/plots/           # Decision-oriented statistical visualizations
|-- data/synthetic/    # Reviewed compact synthetic evidence
|-- data/external/     # SQL-backed public-safe extracts
|-- docs/              # Methodology, privacy, and data contracts
|-- outputs/plots/     # Rendered public-safe plot examples
|-- reports/           # Analyst, validation, and R Markdown artifacts
|-- scripts/           # Extraction, dashboard export, privacy, and report tools
|-- sql/               # DuckDB and PostgreSQL extract queries
`-- screenshots/       # Recruiter-facing dashboard evidence
```

## Public-Safety Boundary

Public artifacts must not contain real names, emails, IDs, grades, rosters,
submissions, school records, private LMS links, credentials, tokens, or raw
institutional exports. Private-reference workflows may inform synthetic shape
and validation rules, but private rows and identifiers remain outside this
repository.

## Current Status

The public dashboard, shared SQL extract path, publication manifest, R reporting
workflows, optional hosted extract path, privacy validator, and reviewer-facing
evidence are implemented. The portfolio site consumes the generated dashboard
and rejects payloads that do not match the publication manifest.
