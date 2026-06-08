# AI Extract Review Prompt Preview

This prompt contains only synthetic public-safe aggregate summaries and report text.

## System Prompt

You review public-safe synthetic assessment extract artifacts for a portfolio project. Treat the SQL outputs as deterministic source-of-truth artifacts. Be direct, conservative, and specific. State that the data is synthetic demo data. Do not imply the data describes real students, teachers, sections, schools, or personnel. Do not invent facts beyond the provided summary.

## User Prompt

Review the synthetic SQL extract package below for portfolio readiness.

Return a compact JSON review with:
- an overall status
- one finding per extract
- quality checks
- brief interpretation
- risks or limitations
- next actions
- portfolio relevance

Keep the review conservative and grounded in the supplied artifacts.

Synthetic extract package:
```json
{
  "extract_directory": "data/external/synthetic-education-data-supabase",
  "extracts": [
    {
      "columns": [
        "grade_level",
        "course_id",
        "course_name",
        "course_track",
        "matched_students",
        "assignment_01_avg",
        "assignment_02_avg",
        "avg_observed_growth_delta",
        "min_observed_growth_delta",
        "max_observed_growth_delta"
      ],
      "decision_question": "Which courses show the clearest Assignment 01 to Assignment 02 growth signals?",
      "extract": "assignment_growth_by_course.csv",
      "nonzero_null_counts": {},
      "numeric_summary": [
        {
          "column": "grade_level",
          "max": 12.0,
          "mean": 10.5,
          "min": 9.0
        },
        {
          "column": "matched_students",
          "max": 41.0,
          "mean": 11.3636,
          "min": 2.0
        },
        {
          "column": "assignment_01_avg",
          "max": 68.19,
          "mean": 48.3768,
          "min": 32.37
        },
        {
          "column": "assignment_02_avg",
          "max": 69.5,
          "mean": 53.9882,
          "min": 41.49
        },
        {
          "column": "avg_observed_growth_delta",
          "max": 11.67,
          "mean": 5.6123,
          "min": 1.32
        },
        {
          "column": "min_observed_growth_delta",
          "max": 2.84,
          "mean": -2.6955,
          "min": -9.86
        },
        {
          "column": "max_observed_growth_delta",
          "max": 21.88,
          "mean": 14.4359,
          "min": 4.81
        }
      ],
      "path": "data/external/synthetic-education-data-supabase/assignment_growth_by_course.csv",
      "rows": 22
    },
    {
      "columns": [
        "course_id",
        "course_name",
        "course_track",
        "section_id",
        "section_label",
        "teacher_id",
        "teacher_label",
        "assignment_label",
        "sequence_index",
        "assessment_window",
        "enrolled_students",
        "present_students",
        "nonparticipation_rate",
        "avg_present_score",
        "min_present_score",
        "max_present_score"
      ],
      "decision_question": "Which course sections have enough assessment evidence to compare performance?",
      "extract": "course_section_performance.csv",
      "nonzero_null_counts": {},
      "numeric_summary": [
        {
          "column": "sequence_index",
          "max": 2.0,
          "mean": 1.5,
          "min": 1.0
        },
        {
          "column": "enrolled_students",
          "max": 18.0,
          "mean": 11.48,
          "min": 8.0
        },
        {
          "column": "present_students",
          "max": 18.0,
          "mean": 10.66,
          "min": 6.0
        },
        {
          "column": "nonparticipation_rate",
          "max": 0.3636,
          "mean": 0.0704,
          "min": 0.0
        },
        {
          "column": "avg_present_score",
          "max": 70.56,
          "mean": 50.3558,
          "min": 28.13
        },
        {
          "column": "min_present_score",
          "max": 60.47,
          "mean": 23.8456,
          "min": 7.28
        },
        {
          "column": "max_present_score",
          "max": 98.96,
          "mean": 81.194,
          "min": 45.98
        }
      ],
      "path": "data/external/synthetic-education-data-supabase/course_section_performance.csv",
      "rows": 50
    },
    {
      "columns": [
        "source_system",
        "school_year",
        "course_id",
        "course_name",
        "course_track",
        "section_id",
        "section_label",
        "teacher_id",
        "teacher_label",
        "reconciliation_status",
        "enrollment_rows",
        "active_enrollments"
      ],
      "decision_question": "Are LMS-style roster records reconciled before dashboard reporting?",
      "extract": "lms_enrollment_reconciliation.csv",
      "nonzero_null_counts": {},
      "numeric_summary": [
        {
          "column": "enrollment_rows",
          "max": 18.0,
          "mean": 11.48,
          "min": 8.0
        },
        {
          "column": "active_enrollments",
          "max": 18.0,
          "mean": 11.48,
          "min": 8.0
        }
      ],
      "path": "data/external/synthetic-education-data-supabase/lms_enrollment_reconciliation.csv",
      "rows": 25
    },
    {
      "columns": [
        "assignment_label",
        "assessment_window",
        "grade_level",
        "attendance_category",
        "course_track",
        "student_assignment_rows",
        "present_rows",
        "nonparticipation_zero_rows",
        "nonparticipation_rate",
        "avg_present_score"
      ],
      "decision_question": "Where are non-participation zeros concentrated before interpreting achievement?",
      "extract": "nonparticipation_by_group.csv",
      "nonzero_null_counts": {
        "avg_present_score": 1
      },
      "numeric_summary": [
        {
          "column": "grade_level",
          "max": 12.0,
          "mean": 10.3448,
          "min": 9.0
        },
        {
          "column": "student_assignment_rows",
          "max": 31.0,
          "mean": 9.8966,
          "min": 1.0
        },
        {
          "column": "present_rows",
          "max": 30.0,
          "mean": 9.1897,
          "min": 0.0
        },
        {
          "column": "nonparticipation_zero_rows",
          "max": 4.0,
          "mean": 0.7069,
          "min": 0.0
        },
        {
          "column": "nonparticipation_rate",
          "max": 1.0,
          "mean": 0.122,
          "min": 0.0
        },
        {
          "column": "avg_present_score",
          "max": 71.34,
          "mean": 52.8677,
          "min": 12.49
        }
      ],
      "path": "data/external/synthetic-education-data-supabase/nonparticipation_by_group.csv",
      "rows": 58
    },
    {
      "columns": [
        "student_dim_id",
        "sis_user_id",
        "student_label",
        "grade_level",
        "attendance_category",
        "course_id",
        "course_name",
        "course_track",
        "section_id",
        "section_label",
        "teacher_id",
        "teacher_label",
        "assignment_01_score",
        "assignment_02_score",
        "observed_growth_delta",
        "modeled_assignment_02_growth_delta",
        "posterior_readiness_after_assignment_02",
        "assignment_02_generation_mode",
        "academic_profile_status"
      ],
      "decision_question": "Which synthetic student readiness records can support readiness views?",
      "extract": "student_readiness_extract.csv",
      "nonzero_null_counts": {
        "modeled_assignment_02_growth_delta": 37,
        "observed_growth_delta": 37,
        "posterior_readiness_after_assignment_02": 22
      },
      "numeric_summary": [
        {
          "column": "student_dim_id",
          "max": 287.0,
          "mean": 144.0,
          "min": 1.0
        },
        {
          "column": "grade_level",
          "max": 12.0,
          "mean": 10.3206,
          "min": 9.0
        },
        {
          "column": "assignment_01_score",
          "max": 98.96,
          "mean": 43.9614,
          "min": 0.0
        },
        {
          "column": "assignment_02_score",
          "max": 95.18,
          "mean": 49.518,
          "min": 0.0
        },
        {
          "column": "observed_growth_delta",
          "max": 21.88,
          "mean": 6.1886,
          "min": -9.86
        },
        {
          "column": "modeled_assignment_02_growth_delta",
          "max": 21.88,
          "mean": 6.1886,
          "min": -9.86
        },
        {
          "column": "posterior_readiness_after_assignment_02",
          "max": 88.2292,
          "mean": 53.098,
          "min": 20.2212
        }
      ],
      "path": "data/external/synthetic-education-data-supabase/student_readiness_extract.csv",
      "rows": 287
    }
  ],
  "guardrails": [
    "Review only the provided synthetic aggregate artifacts.",
    "Do not claim that records describe real students, staff, sections, schools, or personnel.",
    "Do not request or infer private identifiers, contact data, credentials, or raw LMS exports.",
    "Treat OpenAI output as advisory documentation, not a data transformation input."
  ],
  "reports": {
    "analyst_report": {
      "path": "reports/supabase_assessment_report.md",
      "text": "# SQL Warehouse Assessment Report\n\n## Purpose\n\nThis report turns the synthetic SQL extracts into an analyst-facing assessment brief for `assessment-intelligence`. It verifies that the repo can consume SQL-backed marts from `synthetic-education-data` and use them for performance, growth, missingness, readiness when available, and LMS roster quality analysis.\n\n## Source Extracts\n\n| Extract | Rows |\n| --- | --- |\n| `course_section_performance.csv` | 50 |\n| `assignment_growth_by_course.csv` | 22 |\n| `nonparticipation_by_group.csv` | 58 |\n| `lms_enrollment_reconciliation.csv` | 25 |\n| `student_readiness_extract.csv` | 287 |\n\n## Executive Summary\n\n- The current SQL-backed extract set contains 287 synthetic student readiness records across 25 course-section roster groups.\n- The populated assessment windows support beginning-of-year to end-of-year comparisons, with an average section-level present-student score of 50.36.\n- Average section-level non-participation across populated assessment windows is 7.0%, preserving the distinction between attendance/non-participation and academic score evidence.\n- LMS-style roster reconciliation is 287 / 287 matched enrollment rows before downstream reporting.\n\n## Highest Observed Growth By Course\n\n| Grade | Course | Track | Matched Students | Assignment 01 Avg | Assignment 02 Avg | Avg Delta |\n| --- | --- | --- | --- | --- | --- | --- |\n| 9 | Honors Algebra 2 | honors | 13 | 32.37 | 44.04 | 11.67 |\n| 9 | Algebra 1 | regular | 18 | 33.04 | 41.49 | 8.46 |\n| 10 | AP Precalculus | ap | 10 | 51.35 | 59.02 | 7.67 |\n| 10 | Geometry | regular | 13 | 38.47 | 46.11 | 7.64 |\n| 9 | Geometry | regular | 41 | 37.35 | 44.71 | 7.36 |\n| 9 | AP Precalculus | ap | 3 | 49.48 | 56.54 | 7.06 |\n\n## Highest Non-Participation Groups\n\n| Assignment | Grade | Attendance | Track | Rows | Zeros | Rate |\n| --- | --- | --- | --- | --- | --- | --- |\n| Assignment 02 | 10 | at_risk | ap | 1 | 1 | 100.0% |\n| Assignment 02 | 10 | at_risk | regular | 4 | 3 | 75.0% |\n| Assignment 01 | 9 | at_risk | honors | 3 | 2 | 66.7% |\n| Assignment 01 | 11 | at_risk | regular | 5 | 3 | 60.0% |\n| Assignment 02 | 9 | at_risk | regular | 8 | 4 | 50.0% |\n| Assignment 01 | 11 | normal | honors | 5 | 2 | 40.0% |\n\n## Readiness By Track\n\n| Track | Records With Readiness | Avg Posterior Readiness | Avg Observed Growth |\n| --- | --- | --- | --- |\n| ap | 96 | 56.50 | 5.92 |\n| honors | 43 | 55.91 | 7.67 |\n| regular | 126 | 49.55 | 5.95 |\n\n## LMS Roster Reconciliation\n\n| Status | Course-Section Groups |\n| --- | --- |\n| matched | 25 |\n\n## Dashboard And Reporting Uses\n\n- Course-section performance views can be built from `course_section_performance.csv`.\n- Growth diagnostics can use `assignment_growth_by_course.csv` first, then section-level extracts as the dashboard matures.\n- Attendance and missingness views should use `nonparticipation_by_group.csv` so observed zeros are not treated as academic evidence.\n- Data-quality cards can use `lms_enrollment_reconciliation.csv` to show whether LMS-derived rosters are reportable.\n- Student-level readiness views should use `student_readiness_extract.csv` only when that optional extract is present.\n\n## Limitations\n\n- The current public build contains two populated assessment windows; Assignments 03-14 remain intentionally blank until additional longitudinal transitions are implemented.\n- The hosted Supabase extract path reads selected public views from the synthetic warehouse; base `lms` and `analytics` tables remain outside the public API contract.\n- All records are synthetic and public-safe. This report must not be interpreted as containing real student outcomes.\n"
    },
    "extract_report": {
      "path": "reports/supabase_assessment_extract.md",
      "text": "# SQL Warehouse Assessment Extract\n\nGenerated: 2026-06-08 18:52:38 UTC\n\nSource: Supabase public Data API views from `synthetic-education-data`\n\nExtract output directory: `data/external/synthetic-education-data-supabase`\n\n## Purpose\n\nThis report verifies that `assessment-intelligence` can query public-safe synthetic marts from `synthetic-education-data` and produce SQL-backed assessment-analysis extracts.\n\n## Warehouse Summary\n\n| Metric | Value |\n| --- | ---: |\n| Students | 287 |\n| Courses | 9 |\n| Sections | 25 |\n| Teachers | 5 |\n| Assignments | 14 |\n| Assessment score fact rows | 4018 |\n| LMS enrollment fact rows | 287 |\n| Warehouse validation checks passing | 24 / 24 |\n| LMS roster records reconciled | 287 / 287 |\n\n## SQL Extracts\n\n| Extract | Rows |\n| --- | ---: |\n| `course_section_performance.csv` | 50 |\n| `assignment_growth_by_course.csv` | 22 |\n| `nonparticipation_by_group.csv` | 58 |\n| `lms_enrollment_reconciliation.csv` | 25 |\n| `student_readiness_extract.csv` | 287 |\n\n## Analysis Questions Supported\n\n- Which courses and sections show the strongest Assignment 01 to Assignment 02 growth?\n- Where are non-participation zeros concentrated by grade, course track, and attendance category?\n- Do Canvas-derived enrollment records reconcile with canonical synthetic enrollments before reporting?\n- Which star-schema tables should feed future dashboard views in `assessment-intelligence`?\n\n## Recommended Dashboard Inputs\n\n- `course_section_performance.csv` for section-level score views\n- `assignment_growth_by_course.csv` for growth diagnostics\n- `nonparticipation_by_group.csv` for missingness and attendance checks\n- `lms_enrollment_reconciliation.csv` for data-quality status\n- `student_readiness_extract.csv` for student-level synthetic readiness records\n\nAll records are synthetic and public-safe.\n"
    }
  },
  "source": "public-safe synthetic SQL extracts",
  "student_readiness_loaded": true,
  "synthetic_disclosure": "All records are synthetic demo data and must not be interpreted as real student outcomes.",
  "total_extract_rows": 442
}
```
