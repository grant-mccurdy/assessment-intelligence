# AI Extract Review

Mode: `dry-run-local`

Source: `data/external/synthetic-education-data-supabase`

All records are synthetic demo data and must not be interpreted as real student outcomes.

## Overall Status

`portfolio_ready_with_known_limitations`

The package contains 5 synthetic SQL extracts with 442 total aggregate rows. Extraction and interpretation remain separated, which is the right design for reproducibility.

## Extract Findings

| Extract | Rows | Decision Question | Finding |
| --- | --- | --- | --- |
| assignment_growth_by_course.csv | 22 | Which courses show the clearest Assignment 01 to Assignment 02 growth signals? | Contains 22 synthetic aggregate rows and 10 columns for this decision question. |
| course_section_performance.csv | 50 | Which course sections have enough assessment evidence to compare performance? | Contains 50 synthetic aggregate rows and 16 columns for this decision question. |
| lms_enrollment_reconciliation.csv | 25 | Are LMS-style roster records reconciled before dashboard reporting? | Contains 25 synthetic aggregate rows and 12 columns for this decision question. |
| nonparticipation_by_group.csv | 58 | Where are non-participation zeros concentrated before interpreting achievement? | Contains 58 synthetic aggregate rows and 10 columns for this decision question. |
| student_readiness_extract.csv | 287 | Which synthetic student readiness records can support readiness views? | Contains 287 synthetic aggregate rows and 19 columns for this decision question. |

## Quality Checks

| Check | Result | Evidence |
| --- | --- | --- |
| Synthetic data boundary | pass | Input reports explicitly state that all records are synthetic and public-safe. |
| Extract row counts | pass | Each discovered CSV extract has at least one row. |
| Readiness availability | pass | student_readiness_extract.csv is present. |

## Interpretation

- The extract set supports performance, growth, missingness, and roster-quality analysis without exposing raw private records.
- The strongest portfolio signal is the distinction between participation/missingness and score evidence.
- The hosted Supabase path is useful as a serving-layer demonstration while DuckDB remains the reproducible local baseline.

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
