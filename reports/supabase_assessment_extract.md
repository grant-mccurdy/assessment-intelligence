# SQL Warehouse Assessment Extract

Generated: 2026-06-08 18:52:38 UTC

Source: Supabase public Data API views from `synthetic-education-data`

Extract output directory: `data/external/synthetic-education-data-supabase`

## Purpose

This report verifies that `assessment-intelligence` can query public-safe synthetic marts from `synthetic-education-data` and produce SQL-backed assessment-analysis extracts.

## Warehouse Summary

| Metric | Value |
| --- | ---: |
| Students | 287 |
| Courses | 9 |
| Sections | 25 |
| Teachers | 5 |
| Assignments | 14 |
| Assessment score fact rows | 4018 |
| LMS enrollment fact rows | 287 |
| Warehouse validation checks passing | 24 / 24 |
| LMS roster records reconciled | 287 / 287 |

## SQL Extracts

| Extract | Rows |
| --- | ---: |
| `course_section_performance.csv` | 50 |
| `assignment_growth_by_course.csv` | 22 |
| `nonparticipation_by_group.csv` | 58 |
| `lms_enrollment_reconciliation.csv` | 25 |
| `student_readiness_extract.csv` | 287 |

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
