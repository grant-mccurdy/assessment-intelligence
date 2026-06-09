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
  "extract_directory": "data/external/synthetic-education-data",
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
          "mean": 10.6667,
          "min": 9.0
        },
        {
          "column": "matched_students",
          "max": 233.0,
          "mean": 64.3333,
          "min": 1.0
        },
        {
          "column": "assignment_01_avg",
          "max": 94.16,
          "mean": 55.2059,
          "min": 36.86
        },
        {
          "column": "assignment_02_avg",
          "max": 93.37,
          "mean": 60.3256,
          "min": 42.4
        },
        {
          "column": "avg_observed_growth_delta",
          "max": 15.92,
          "mean": 5.1215,
          "min": -2.48
        },
        {
          "column": "min_observed_growth_delta",
          "max": 15.92,
          "mean": -3.9115,
          "min": -11.11
        },
        {
          "column": "max_observed_growth_delta",
          "max": 24.23,
          "mean": 14.5222,
          "min": -0.79
        }
      ],
      "path": "data/external/synthetic-education-data/assignment_growth_by_course.csv",
      "rows": 27
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
          "max": 14.0,
          "mean": 7.477,
          "min": 1.0
        },
        {
          "column": "enrolled_students",
          "max": 14.0,
          "mean": 11.546,
          "min": 4.0
        },
        {
          "column": "present_students",
          "max": 14.0,
          "mean": 10.7184,
          "min": 3.0
        },
        {
          "column": "nonparticipation_rate",
          "max": 0.5,
          "mean": 0.0725,
          "min": 0.0
        },
        {
          "column": "avg_present_score",
          "max": 81.71,
          "mean": 51.9193,
          "min": 29.49
        },
        {
          "column": "min_present_score",
          "max": 66.58,
          "mean": 25.6764,
          "min": 3.75
        },
        {
          "column": "max_present_score",
          "max": 100.0,
          "mean": 78.1474,
          "min": 41.64
        }
      ],
      "path": "data/external/synthetic-education-data/course_section_performance.csv",
      "rows": 348
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
          "max": 14.0,
          "mean": 11.546,
          "min": 4.0
        },
        {
          "column": "active_enrollments",
          "max": 14.0,
          "mean": 11.546,
          "min": 4.0
        }
      ],
      "path": "data/external/synthetic-education-data/lms_enrollment_reconciliation.csv",
      "rows": 174
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
        "avg_present_score": 20
      },
      "numeric_summary": [
        {
          "column": "grade_level",
          "max": 12.0,
          "mean": 10.5152,
          "min": 9.0
        },
        {
          "column": "student_assignment_rows",
          "max": 37.0,
          "mean": 8.697,
          "min": 1.0
        },
        {
          "column": "present_rows",
          "max": 36.0,
          "mean": 8.0736,
          "min": 0.0
        },
        {
          "column": "nonparticipation_zero_rows",
          "max": 5.0,
          "mean": 0.6234,
          "min": 0.0
        },
        {
          "column": "nonparticipation_rate",
          "max": 1.0,
          "mean": 0.1223,
          "min": 0.0
        },
        {
          "column": "avg_present_score",
          "max": 94.05,
          "mean": 53.727,
          "min": 11.14
        }
      ],
      "path": "data/external/synthetic-education-data/nonparticipation_by_group.csv",
      "rows": 462
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
        "boy_assignment_label",
        "eoy_assignment_label",
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
        "modeled_assignment_02_growth_delta": 194,
        "observed_growth_delta": 272,
        "posterior_readiness_after_assignment_02": 149
      },
      "numeric_summary": [
        {
          "column": "student_dim_id",
          "max": 2009.0,
          "mean": 1005.0,
          "min": 1.0
        },
        {
          "column": "grade_level",
          "max": 12.0,
          "mean": 10.4913,
          "min": 9.0
        },
        {
          "column": "assignment_01_score",
          "max": 100.0,
          "mean": 45.1595,
          "min": 0.0
        },
        {
          "column": "assignment_02_score",
          "max": 100.0,
          "mean": 50.2215,
          "min": 0.0
        },
        {
          "column": "observed_growth_delta",
          "max": 24.23,
          "mean": 5.7249,
          "min": -11.11
        },
        {
          "column": "modeled_assignment_02_growth_delta",
          "max": 24.23,
          "mean": 5.6239,
          "min": -14.72
        },
        {
          "column": "posterior_readiness_after_assignment_02",
          "max": 98.7692,
          "mean": 53.4499,
          "min": 11.8766
        }
      ],
      "path": "data/external/synthetic-education-data/student_readiness_extract.csv",
      "rows": 2009
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
      "path": "reports/sql_warehouse_assessment_report.md",
      "text": "# SQL Warehouse Assessment Report\n\n## Purpose\n\nThis report turns the synthetic SQL extracts into an analyst-facing assessment brief for `assessment-intelligence`. It verifies that the repo can consume SQL-backed marts from `synthetic-education-data` and use them for performance, growth, missingness, readiness when available, and LMS roster quality analysis.\n\n## Source Extracts\n\n| Extract | Rows |\n| --- | --- |\n| `course_section_performance.csv` | 348 |\n| `assignment_growth_by_course.csv` | 27 |\n| `nonparticipation_by_group.csv` | 462 |\n| `lms_enrollment_reconciliation.csv` | 174 |\n| `student_readiness_extract.csv` | 2009 |\n\n## Executive Summary\n\n- The current SQL-backed extract set contains 2009 synthetic student readiness records across 174 course-section roster groups.\n- The populated extract contains 14 assessment windows, with an average section-level present-student score of 51.92.\n- Average section-level non-participation across populated assessment windows is 7.2%, preserving the distinction between attendance/non-participation and academic score evidence.\n- LMS-style roster reconciliation is 2009 / 2009 matched enrollment rows before downstream reporting.\n\n## Highest Observed Growth By Course\n\n| Grade | Course | Track | Matched Students | Assignment 01 Avg | Assignment 02 Avg | Avg Delta |\n| --- | --- | --- | --- | --- | --- | --- |\n| 10 | Algebra 1 | regular | 1 | 38.90 | 54.82 | 15.92 |\n| 9 | AP Precalculus | ap | 15 | 39.97 | 47.81 | 7.85 |\n| 9 | Honors Algebra 2 | honors | 86 | 45.92 | 53.18 | 7.26 |\n| 9 | Geometry | regular | 233 | 41.61 | 48.32 | 6.71 |\n| 10 | Algebra 2 | regular | 161 | 37.39 | 44.09 | 6.70 |\n| 10 | AP Precalculus | ap | 88 | 51.57 | 58.12 | 6.55 |\n\n## Highest Non-Participation Groups\n\n| Assignment | Grade | Attendance | Track | Rows | Zeros | Rate |\n| --- | --- | --- | --- | --- | --- | --- |\n| Assignment 01 | 11 | at_risk | regular | 1 | 1 | 100.0% |\n| Assignment 02 | 10 | at_risk | honors | 1 | 1 | 100.0% |\n| Assignment 03 | 9 | at_risk | honors | 1 | 1 | 100.0% |\n| Assignment 03 | 12 | at_risk | regular | 1 | 1 | 100.0% |\n| Assignment 05 | 9 | normal | honors | 1 | 1 | 100.0% |\n| Assignment 05 | 12 | at_risk | beyond_core | 1 | 1 | 100.0% |\n\n## Readiness By Track\n\n| Track | Records With Readiness | Avg Posterior Readiness | Avg Observed Growth |\n| --- | --- | --- | --- |\n| ap | 668 | 60.24 | 4.90 |\n| beyond_core | 27 | 71.91 | 3.08 |\n| honors | 215 | 62.41 | 6.12 |\n| regular | 950 | 46.12 | 6.30 |\n\n## LMS Roster Reconciliation\n\n| Status | Course-Section Groups |\n| --- | --- |\n| matched | 174 |\n\n## Dashboard And Reporting Uses\n\n- Course-section performance views can be built from `course_section_performance.csv`.\n- Growth diagnostics can use `assignment_growth_by_course.csv` first, then section-level extracts as the dashboard matures.\n- Attendance and missingness views should use `nonparticipation_by_group.csv` so observed zeros are not treated as academic evidence.\n- Data-quality cards can use `lms_enrollment_reconciliation.csv` to show whether LMS-derived rosters are reportable.\n- Student-level readiness views should use `student_readiness_extract.csv` only when that optional extract is present.\n\n## Limitations\n\n- The current public build contains 14 populated assessment windows exported from the synthetic warehouse marts.\n- The hosted Supabase extract path reads selected public views from the synthetic warehouse; base `lms` and `analytics` tables remain outside the public API contract.\n- All records are synthetic and public-safe. This report must not be interpreted as containing real student outcomes.\n"
    },
    "extract_report": {
      "path": "reports/sql_warehouse_assessment_extract.md",
      "text": "# SQL Warehouse Assessment Extract\n\nGenerated: 2026-06-09 20:08:50 UTC\n\nSource: `synthetic-education-data/warehouse/synthetic_math.duckdb`\n\nExtract output directory: `data/external/synthetic-education-data`\n\n## Purpose\n\nThis report verifies that `assessment-intelligence` can query public-safe synthetic marts from `synthetic-education-data` and produce SQL-backed assessment-analysis extracts.\n\n## Warehouse Summary\n\n| Metric | Value |\n| --- | ---: |\n| Students | 696 |\n| Courses | 9 |\n| Sections | 174 |\n| Teachers | 35 |\n| Assignments | 14 |\n| Assessment score fact rows | 4018 |\n| LMS enrollment fact rows | 2009 |\n| Warehouse validation checks passing | 20 / 20 |\n| LMS roster records reconciled | 2009 / 2009 |\n\n## SQL Extracts\n\n| Extract | Rows |\n| --- | ---: |\n| `course_section_performance.csv` | 348 |\n| `assignment_growth_by_course.csv` | 27 |\n| `nonparticipation_by_group.csv` | 462 |\n| `lms_enrollment_reconciliation.csv` | 174 |\n| `student_readiness_extract.csv` | 2009 |\n\n## Analysis Questions Supported\n\n- Which courses and sections show the strongest Assignment 01 to Assignment 02 growth?\n- Where are non-participation zeros concentrated by grade, course track, and attendance category?\n- Do Canvas-derived enrollment records reconcile with canonical synthetic enrollments before reporting?\n- Which star-schema tables should feed future dashboard views in `assessment-intelligence`?\n\n## Recommended Dashboard Inputs\n\n- `course_section_performance.csv` for section-level score views\n- `assignment_growth_by_course.csv` for growth diagnostics\n- `nonparticipation_by_group.csv` for missingness and attendance checks\n- `lms_enrollment_reconciliation.csv` for data-quality status\n- `student_readiness_extract.csv` for student-level synthetic readiness records\n\nAll records are synthetic and public-safe.\n"
    }
  },
  "source": "public-safe synthetic SQL extracts",
  "student_readiness_loaded": true,
  "synthetic_disclosure": "All records are synthetic demo data and must not be interpreted as real student outcomes.",
  "total_extract_rows": 3020
}
```
