# SQL Warehouse Assessment Extract

Generated: 2026-07-20 19:36:39 UTC

Source: `education-data-simulation-engine/warehouse/synthetic_math.duckdb`

Extract output directory: `data/external/education-data-simulation-engine`

## Purpose

This report verifies that `assessment-intelligence` can query public-safe synthetic marts from `education-data-simulation-engine` and produce SQL-backed assessment-analysis extracts.

## Warehouse Summary

| Metric | Value |
| --- | ---: |
| Students | 696 |
| Courses | 9 |
| Sections | 174 |
| Teachers | 35 |
| Assignments | 14 |
| Assessment score fact rows | 4018 |
| LMS enrollment fact rows | 2009 |
| Warehouse validation checks passing | 20 / 20 |
| LMS roster records reconciled | 2009 / 2009 |

## SQL Extracts

| Extract | Rows |
| --- | ---: |
| `course_section_performance.csv` | 348 |
| `assignment_growth_by_course.csv` | 27 |
| `nonparticipation_by_group.csv` | 462 |
| `lms_enrollment_reconciliation.csv` | 174 |
| `student_readiness_extract.csv` | 2009 |

## Analysis Questions Supported

- Which courses and sections show the strongest Assignment 01 to Assignment 02 growth?
- Where are non-participation zeros concentrated by grade, course track, and attendance category?
- Do Canvas-derived enrollment records reconcile with canonical synthetic enrollments before reporting?
- Which star-schema tables should feed future dashboard views in `assessment-intelligence`?

## Recommended Dashboard Inputs

- `course_section_performance.csv` for section-level score views
- `assignment_growth_by_course.csv` for growth diagnostics
- `nonparticipation_by_group.csv` for missingness and attendance checks
- `lms_enrollment_reconciliation.csv` for data-quality status
- `student_readiness_extract.csv` for student-level synthetic readiness records

All records are synthetic and public-safe.
