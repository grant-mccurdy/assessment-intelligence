# AI Assessment Memo Prompt Preview

This prompt contains only synthetic public-safe aggregate summary data.

## System Prompt

You draft concise academic leadership memos from public-safe synthetic assessment dashboard summaries. Be restrained, specific, and action oriented. State clearly that the data is synthetic demo data. Do not imply that the data describes real students, teachers, sections, or a real school. Do not invent facts beyond the supplied summary.

## User Prompt

Draft a department-chair leadership memo from the synthetic assessment summary below.

Requirements:
- Title the memo.
- Start with one sentence stating this is synthetic demo data.
- Include three trends, two risks or watch items, and three next actions.
- Keep it under 450 words.
- Use restrained professional language for school leaders.
- Do not invent details beyond the summary.

Synthetic summary:
```json
{
  "course_summaries": [
    {
      "change": -0.9,
      "completion": 92.7,
      "course": "AP Calculus AB",
      "latest_score": 55.0,
      "proficiency": 14.1,
      "students": 55
    },
    {
      "change": 3.7,
      "completion": 87.5,
      "course": "AP Calculus BC",
      "latest_score": 65.6,
      "proficiency": 38.2,
      "students": 24
    },
    {
      "change": 14.4,
      "completion": 100.0,
      "course": "AP Precalculus",
      "latest_score": 69.8,
      "proficiency": 55.9,
      "students": 34
    },
    {
      "change": 17.9,
      "completion": 100.0,
      "course": "Algebra 1",
      "latest_score": 49.2,
      "proficiency": 15.4,
      "students": 13
    },
    {
      "change": -2.0,
      "completion": 91.7,
      "course": "Algebra 2",
      "latest_score": 45.5,
      "proficiency": 0.0,
      "students": 36
    },
    {
      "change": 6.1,
      "completion": 95.9,
      "course": "Geometry",
      "latest_score": 51.4,
      "proficiency": 17.2,
      "students": 48
    },
    {
      "change": 17.4,
      "completion": 100.0,
      "course": "Honors Algebra 2",
      "latest_score": 68.5,
      "proficiency": 42.9,
      "students": 28
    },
    {
      "change": -6.4,
      "completion": 93.3,
      "course": "Precalculus",
      "latest_score": 46.0,
      "proficiency": 0.0,
      "students": 45
    }
  ],
  "guardrails": [
    "Do not claim this data is real.",
    "Do not identify students, teachers, sections, or schools.",
    "Use the memo as a portfolio demonstration of assessment reporting workflow design."
  ],
  "latest_completion": 94.8,
  "latest_period": "Assignment 14",
  "latest_proficiency": 20.6,
  "latest_score": 55.6,
  "lowest_completion": [
    {
      "change": 3.7,
      "completion": 87.5,
      "course": "AP Calculus BC",
      "latest_score": 65.6,
      "proficiency": 38.2,
      "students": 24
    },
    {
      "change": -2.0,
      "completion": 91.7,
      "course": "Algebra 2",
      "latest_score": 45.5,
      "proficiency": 0.0,
      "students": 36
    }
  ],
  "lowest_skill_signals": [
    {
      "signal": 20.5,
      "skill": "Proficiency"
    },
    {
      "signal": 52.2,
      "skill": "Readiness"
    },
    {
      "signal": 55.6,
      "skill": "Score"
    },
    {
      "signal": 94.9,
      "skill": "Completion"
    }
  ],
  "period_window": "Assignment 01 to Assignment 14",
  "score_change_from_baseline": 5.6,
  "source": "synthetic public dashboard JSON",
  "strongest_growth": [
    {
      "change": 17.9,
      "completion": 100.0,
      "course": "Algebra 1",
      "latest_score": 49.2,
      "proficiency": 15.4,
      "students": 13
    },
    {
      "change": 17.4,
      "completion": 100.0,
      "course": "Honors Algebra 2",
      "latest_score": 68.5,
      "proficiency": 42.9,
      "students": 28
    }
  ],
  "students_latest_period": 287,
  "synthetic_disclosure": "Synthetic assessment dashboard data generated from the same SQL warehouse extracts used by assessment-intelligence report artifacts. No real students, rosters, teachers, sections, IDs, emails, grades, submissions, or school records are included."
}
```
