# AI Extract Review

Mode: `dry-run-local`

Source: `data/external/education-data-simulation-engine`

All records are synthetic demo data and must not be interpreted as real student outcomes.

## Overall Status

`portfolio_ready_with_known_limitations`

The package contains 5 synthetic SQL extracts with 3020 total aggregate rows. Extraction and interpretation remain separated, which is the right design for reproducibility.

## Extract Findings

| Extract | Rows | Decision Question | Finding |
| --- | --- | --- | --- |
| assignment_growth_by_course.csv | 27 | Which courses show the clearest Assignment 01 to Assignment 02 growth signals? | Contains 27 synthetic aggregate rows and 10 columns for this decision question. |
| course_section_performance.csv | 348 | Which course sections have enough assessment evidence to compare performance? | Contains 348 synthetic aggregate rows and 16 columns for this decision question. |
| lms_enrollment_reconciliation.csv | 174 | Are LMS-style roster records reconciled before dashboard reporting? | Contains 174 synthetic aggregate rows and 12 columns for this decision question. |
| nonparticipation_by_group.csv | 462 | Where are non-participation zeros concentrated before interpreting achievement? | Contains 462 synthetic aggregate rows and 10 columns for this decision question. |
| student_readiness_extract.csv | 2009 | Which synthetic student readiness records can support readiness views? | Contains 2009 synthetic aggregate rows and 21 columns for this decision question. |

## Quality Checks

| Check | Result | Evidence |
| --- | --- | --- |
| Synthetic data boundary | pass | Input reports explicitly state that all records are synthetic and public-safe. |
| Extract row counts | pass | Each discovered CSV extract has at least one row. |
| Readiness availability | pass | student_readiness_extract.csv is present. |

## Interpretation

- The extract set supports performance, growth, missingness, and roster-quality analysis without exposing raw private records.
- The strongest portfolio signal is the distinction between participation/missingness and score evidence.
- The DuckDB-backed extract path is the reproducible local baseline; hosted Supabase remains an optional serving-layer demonstration.

## Risks And Limitations

- The OpenAI review is advisory and should not become an input to downstream data generation or CSV exports.
- Student-level readiness views should stay curated through the public view contract and should not expose raw LMS staging rows.
- Future examples should continue using aggregate summaries rather than raw LMS rows or real learner records.

## Next Actions

- Keep the deterministic SQL extracts as the source of truth.
- Add a small public data dictionary for each extract before expanding dashboard views.
- Add a focused dashboard fixture for the readiness extract before expanding dashboard views.

## Portfolio Relevance

This demonstrates a defensible AI-assisted analytics pattern: deterministic extraction first, then public-safe narrative review over aggregate synthetic artifacts.
