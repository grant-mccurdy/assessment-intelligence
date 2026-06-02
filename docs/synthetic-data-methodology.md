# Synthetic Data Methodology

This project should demonstrate a privacy-aware assessment analytics workflow:
real institutional signal can shape a synthetic dataset, but private rows and
identifiers never leave the private workspace.

```text
private assessment export
-> private distribution profiling
-> aggregate calibration parameters
-> synthetic student/section/time-series generator
-> privacy and schema validation
-> public dashboard and reports
```

## What Is Preserved

The synthetic dataset can preserve useful analytical structure:

- score distribution shape
- completion and non-participation patterns
- item-count constraints
- course, grade, teacher, and section variation
- fall/spring time-series behavior
- growth and proficiency metrics
- skill-domain patterns for dashboarding

This makes the public dashboard useful as an analytics demonstration rather than
a random mockup.

## What Is Destroyed

The public dataset must not preserve:

- real student names, emails, IDs, or rosters
- exact rows from LMS exports
- Canvas URLs, assignment IDs, user IDs, submission IDs, or course IDs
- private teacher names or internal section labels
- grades, submissions, comments, or private assessment artifacts
- rare combinations that could identify a person or class

The public output should use clearly fake labels such as `Teacher A`, generated
student IDs, synthetic section IDs, and public-safe course categories.

## Bootstrapping Approach

The generator may sample from a private score distribution only after the source
has been reduced to calibration signal. A safe pattern is:

1. Read a private export in a private workspace.
2. Strip all identifiers and non-score fields.
3. Estimate distribution shape from score values.
4. Model non-completion separately from true zero performance.
5. Generate new synthetic student histories with fake IDs and fake sections.
6. Add course/section/time effects so dashboards show realistic variation.
7. Validate the public JSON before publishing.

The public repo should contain generated synthetic data and methodology, not the
private export or the private profiling output.

## OpenAI-Assisted Enhancements

OpenAI API calls can make the workflow more marketable when they operate only on
synthetic or aggregate data:

- generate leadership memo drafts from synthetic dashboard trends
- produce data dictionary explanations from public schema fields
- suggest public-safe skill labels, misconception categories, and remediation
  themes
- review a synthetic dataset against privacy rules and return an audit checklist
- convert dashboard observations into restrained decision notes

Do not send raw student-level private exports, student names, parent data, Canvas
records, or school-private documents to an API for this public workflow.

The first implemented API-ready artifact is:

```text
scripts/generate_ai_assessment_memo.py
```

It summarizes the public synthetic dashboard JSON, writes a prompt preview, and
creates a local memo draft by default. A real OpenAI call requires `--call-api`.

## Validation

Run the validator against the current public dashboard JSON:

```bash
python3 scripts/validate_synthetic_privacy.py \
  --input ../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json
```

The report is written to:

```text
reports/synthetic-data-validation-report.md
```
