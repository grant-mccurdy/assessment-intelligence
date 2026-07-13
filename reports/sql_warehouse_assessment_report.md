# SQL Warehouse Assessment Report

## Purpose

This report turns the synthetic SQL extracts into an analyst-facing assessment brief for `assessment-intelligence`. It verifies that the repo can consume SQL-backed marts from `education-data-simulation-engine` and use them for performance, growth, missingness, readiness when available, and LMS roster quality analysis.

## Source Extracts

| Extract | Rows |
| --- | --- |
| `course_section_performance.csv` | 348 |
| `assignment_growth_by_course.csv` | 27 |
| `nonparticipation_by_group.csv` | 462 |
| `lms_enrollment_reconciliation.csv` | 174 |
| `student_readiness_extract.csv` | 2009 |

## Executive Summary

- The current SQL-backed extract set contains 2009 synthetic student readiness records across 174 course-section roster groups.
- The populated extract contains 14 assessment windows, with an average section-level present-student score of 51.92.
- Average section-level non-participation across populated assessment windows is 7.2%, preserving the distinction between attendance/non-participation and academic score evidence.
- LMS-style roster reconciliation is 2009 / 2009 matched enrollment rows before downstream reporting.

## Highest Observed Growth By Course (n >= 10)

| Grade | Course | Track | Matched Students | Assignment 01 Avg | Assignment 02 Avg | Avg Delta |
| --- | --- | --- | --- | --- | --- | --- |
| 9 | AP Precalculus | ap | 15 | 39.97 | 47.81 | 7.85 |
| 9 | Honors Algebra 2 | honors | 86 | 45.92 | 53.18 | 7.26 |
| 9 | Geometry | regular | 233 | 41.61 | 48.32 | 6.71 |
| 10 | Algebra 2 | regular | 161 | 37.39 | 44.09 | 6.70 |
| 10 | AP Precalculus | ap | 88 | 51.57 | 58.12 | 6.55 |
| 9 | Algebra 1 | regular | 92 | 38.67 | 45.17 | 6.50 |

Comparative rankings exclude groups with fewer than 10 matched students.

## Highest Non-Participation Groups (n >= 10)

| Assignment | Grade | Attendance | Track | Rows | Zeros | Rate |
| --- | --- | --- | --- | --- | --- | --- |
| Assignment 12 | 9 | normal | honors | 10 | 3 | 30.0% |
| Assignment 06 | 9 | normal | regular | 19 | 5 | 26.3% |
| Assignment 12 | 11 | normal | regular | 22 | 5 | 22.7% |
| Assignment 01 | 10 | normal | regular | 25 | 5 | 20.0% |
| Assignment 12 | 10 | normal | ap | 10 | 2 | 20.0% |
| Assignment 12 | 11 | normal | ap | 21 | 4 | 19.1% |

Comparative rankings exclude groups with fewer than 10 student-assignment rows.

## Readiness By Track

| Track | Records With Readiness | Avg Posterior Readiness | Avg Observed Growth |
| --- | --- | --- | --- |
| ap | 668 | 60.24 | 4.90 |
| beyond_core | 27 | 71.91 | 3.08 |
| honors | 215 | 62.41 | 6.12 |
| regular | 950 | 46.12 | 6.30 |

## LMS Roster Reconciliation

| Status | Course-Section Groups |
| --- | --- |
| matched | 174 |

## Dashboard And Reporting Uses

- Course-section performance views can be built from `course_section_performance.csv`.
- Growth diagnostics can use `assignment_growth_by_course.csv` first, then section-level extracts as the dashboard matures.
- Attendance and missingness views should use `nonparticipation_by_group.csv` so observed zeros are not treated as academic evidence.
- Data-quality cards can use `lms_enrollment_reconciliation.csv` to show whether LMS-derived rosters are reportable.
- Student-level readiness views should use `student_readiness_extract.csv` only when that optional extract is present.

## Limitations

- The current public build contains 14 populated assessment windows exported from the synthetic warehouse marts.
- Small synthetic groups remain available for data-quality inspection but are excluded from ranked decision insights when n < 10.
- The hosted Supabase extract path reads selected public views from the synthetic warehouse; base `lms` and `analytics` tables remain outside the public API contract.
- All records are synthetic and public-safe. This report must not be interpreted as containing real student outcomes.
