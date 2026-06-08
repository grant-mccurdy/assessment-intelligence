# OpenAI-Assisted Reporting

OpenAI calls should be treated as a reporting layer over public-safe artifacts,
not as a processor for raw private data.

## Safe Inputs

- synthetic dashboard JSON
- aggregate metrics
- fake course, teacher, section, and skill labels
- public data dictionaries
- public validation reports

## Unsafe Inputs

- raw LMS exports
- real student records
- parent or student emails
- private teacher names
- Canvas URLs, IDs, submissions, comments, or grades
- private school documents

## High-Value API Features

### Post-Extract Review

Use OpenAI after deterministic SQL extraction to review public-safe aggregate
artifacts for portfolio readiness, quality checks, limitations, and next
actions. The model does not query Supabase, edit CSVs, or become a source of
truth for downstream data.

Implemented script:

```bash
python3 scripts/generate_ai_extract_review.py
```

Default behavior is a dry run. It writes:

```text
reports/ai-extract-review-prompt.md
reports/ai-extract-review.json
reports/ai-extract-review.md
```

To make a real API call, pass an explicit flag and an optional env file after
confirming the inputs are synthetic/public-safe:

```bash
python3 scripts/generate_ai_extract_review.py --env-file ../../.env --call-api
```

The API path uses the OpenAI Responses API with `store: false`. The extract
review requests structured JSON output so the final Markdown report can be
rendered deterministically.

### Leadership Memo Draft

Use synthetic aggregate trends to draft a short memo:

```text
Given this synthetic dashboard summary, write a restrained department-chair
memo with three trends, two risks, and three next actions. Do not claim the data
is real. Do not identify students or teachers.
```

Implemented script:

```bash
python3 scripts/generate_ai_assessment_memo.py
```

Default behavior is a dry run. It writes:

```text
reports/ai-assessment-memo-prompt.md
reports/sample-leadership-memo.md
```

To make a real API call, pass an explicit flag after confirming the input is
synthetic/public-safe:

```bash
python3 scripts/generate_ai_assessment_memo.py --call-api
```

API scripts read `OPENAI_API_KEY` from the current environment. They can also
load only OpenAI allowlisted variables from an explicit env file:

```bash
python3 scripts/generate_ai_assessment_memo.py --env-file ../../.env --call-api
```

### Data Dictionary Assistant

Use public schema fields to create plain-English metric definitions for
dashboard users.

### Privacy Audit Assistant

Use public validation output and privacy rules to generate a checklist for
release review.

### Skill Label Enrichment

Use public course names and broad mathematical domains to suggest synthetic
skill labels and remediation categories.

## Implementation Rule

API scripts should default to dry-run or prompt-preview mode. A human should
explicitly approve any networked call that could spend credits or process data.
OpenAI output is advisory documentation only; it should not overwrite extract
CSV files or feed downstream synthetic-data generation.
