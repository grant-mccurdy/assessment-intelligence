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

The script reads `OPENAI_API_KEY` only from the environment and does not read
`.env` files.

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
