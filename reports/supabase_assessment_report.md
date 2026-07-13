# SQL Warehouse Assessment Report

## Purpose

This report turns the synthetic SQL extracts into an analyst-facing assessment brief for `assessment-intelligence`. It verifies that the repo can consume SQL-backed marts from `education-data-simulation-engine` and use them for performance, growth, missingness, readiness when available, and LMS roster quality analysis.

## Source Extracts

| Extract | Rows |
| --- | --- |
| `course_section_performance.csv` | 50 |
| `assignment_growth_by_course.csv` | 22 |
| `nonparticipation_by_group.csv` | 58 |
| `lms_enrollment_reconciliation.csv` | 25 |
| `student_readiness_extract.csv` | 287 |

## Executive Summary

- The current SQL-backed extract set contains 287 synthetic student readiness records across 25 course-section roster groups.
- The populated extract contains 2 assessment windows, with an average section-level present-student score of 50.36.
- Average section-level non-participation across populated assessment windows is 7.0%, preserving the distinction between attendance/non-participation and academic score evidence.
- LMS-style roster reconciliation is 287 / 287 matched enrollment rows before downstream reporting.

## Highest Observed Growth By Course (n >= 10)

| Grade | Course | Track | Matched Students | Assignment 01 Avg | Assignment 02 Avg | Avg Delta |
| --- | --- | --- | --- | --- | --- | --- |
| 9 | Honors Algebra 2 | honors | 13 | 32.37 | 44.04 | 11.67 |
| 9 | Algebra 1 | regular | 18 | 33.04 | 41.49 | 8.46 |
| 10 | AP Precalculus | ap | 10 | 51.35 | 59.02 | 7.67 |
| 10 | Geometry | regular | 13 | 38.47 | 46.11 | 7.64 |
| 9 | Geometry | regular | 41 | 37.35 | 44.71 | 7.36 |
| 12 | AP Calculus AB | ap | 24 | 47.12 | 53.21 | 6.09 |

Comparative rankings exclude groups with fewer than 10 matched students.

## Highest Non-Participation Groups (n >= 10)

| Assignment | Grade | Attendance | Track | Rows | Zeros | Rate |
| --- | --- | --- | --- | --- | --- | --- |
| Assignment 02 | 10 | normal | regular | 18 | 2 | 11.1% |
| Assignment 02 | 9 | normal | regular | 31 | 3 | 9.7% |
| Assignment 01 | 10 | normal | regular | 18 | 1 | 5.6% |
| Assignment 01 | 10 | high | regular | 23 | 1 | 4.3% |
| Assignment 02 | 10 | high | regular | 23 | 1 | 4.3% |
| Assignment 02 | 12 | normal | ap | 24 | 1 | 4.2% |

Comparative rankings exclude groups with fewer than 10 student-assignment rows.

## Readiness By Track

| Track | Records With Readiness | Avg Posterior Readiness | Avg Observed Growth |
| --- | --- | --- | --- |
| ap | 96 | 56.50 | 5.92 |
| honors | 43 | 55.91 | 7.67 |
| regular | 126 | 49.55 | 5.95 |

## LMS Roster Reconciliation

| Status | Course-Section Groups |
| --- | --- |
| matched | 25 |

## Dashboard And Reporting Uses

- Course-section performance views can be built from `course_section_performance.csv`.
- Growth diagnostics can use `assignment_growth_by_course.csv` first, then section-level extracts as the dashboard matures.
- Attendance and missingness views should use `nonparticipation_by_group.csv` so observed zeros are not treated as academic evidence.
- Data-quality cards can use `lms_enrollment_reconciliation.csv` to show whether LMS-derived rosters are reportable.
- Student-level readiness views should use `student_readiness_extract.csv` only when that optional extract is present.

## Limitations

- The current public build contains 2 populated assessment windows exported from the synthetic warehouse marts.
- Small synthetic groups remain available for data-quality inspection but are excluded from ranked decision insights when n < 10.
- The hosted Supabase extract path reads selected public views from the synthetic warehouse; base `lms` and `analytics` tables remain outside the public API contract.
- All records are synthetic and public-safe. This report must not be interpreted as containing real student outcomes.
