#!/usr/bin/env python3
"""Generate a leadership memo from public-safe synthetic assessment data.

Default mode is a local dry run: it writes the prompt preview and a deterministic
memo draft without making a network call. Pass --call-api to send only the
synthetic aggregate summary to OpenAI.
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path
from typing import Any

from openai_public_safe import call_openai_response, load_openai_config

SYSTEM_PROMPT = (
    "You draft concise academic leadership memos from public-safe synthetic "
    "assessment dashboard summaries. Be restrained, specific, and action "
    "oriented. State clearly that the data is synthetic demo data. Do not imply "
    "that the data describes real students, teachers, sections, or a real "
    "school. Do not invent facts beyond the supplied summary."
)


def load_json(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("Input JSON must be an object.")
    return data


def weighted_average(rows: list[dict[str, Any]], key: str, weight_key: str = "students") -> float:
    total = sum(float(row.get(weight_key, 0) or 0) for row in rows)
    if total <= 0:
        return 0.0
    return sum(float(row.get(key, 0) or 0) * float(row.get(weight_key, 0) or 0) for row in rows) / total


def group_by(rows: list[dict[str, Any]], key: str) -> dict[str, list[dict[str, Any]]]:
    groups: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for row in rows:
        groups[str(row.get(key, "Unknown"))].append(row)
    return dict(groups)


def summarize_by_course(records: list[dict[str, Any]], first_order: int, latest_order: int) -> list[dict[str, Any]]:
    summaries = []
    for course, rows in group_by(records, "course").items():
        first_rows = [row for row in rows if row.get("order") == first_order]
        latest_rows = [row for row in rows if row.get("order") == latest_order]
        if not first_rows or not latest_rows:
            continue
        first_score = weighted_average(first_rows, "score")
        latest_score = weighted_average(latest_rows, "score")
        summaries.append(
            {
                "course": course,
                "students": int(sum(row.get("students", 0) or 0 for row in latest_rows)),
                "latest_score": round(latest_score, 1),
                "change": round(latest_score - first_score, 1),
                "completion": round(weighted_average(latest_rows, "completion"), 1),
                "proficiency": round(weighted_average(latest_rows, "proficiency"), 1),
            }
        )
    return sorted(summaries, key=lambda item: item["course"])


def summarize_skills(latest_rows: list[dict[str, Any]], limit: int = 5) -> list[dict[str, Any]]:
    skill_values: dict[str, list[float]] = defaultdict(list)
    for row in latest_rows:
        skills = row.get("skills") or {}
        if not isinstance(skills, dict):
            continue
        for skill, value in skills.items():
            if isinstance(value, (int, float)):
                skill_values[str(skill)].append(float(value))
    summaries = [
        {"skill": skill, "signal": round(sum(values) / len(values), 1)}
        for skill, values in skill_values.items()
        if values
    ]
    return sorted(summaries, key=lambda item: item["signal"])[:limit]


def build_summary(data: dict[str, Any]) -> dict[str, Any]:
    records = data.get("records", [])
    if not isinstance(records, list) or not records:
        raise ValueError("Input JSON must include a non-empty records list.")
    orders = sorted({int(row.get("order", 0)) for row in records if row.get("order") is not None})
    if not orders:
        raise ValueError("Records must include period order values.")
    first_order = orders[0]
    latest_order = orders[-1]
    first_rows = [row for row in records if row.get("order") == first_order]
    latest_rows = [row for row in records if row.get("order") == latest_order]
    first_label = str(first_rows[0].get("periodLabel", f"Period {first_order}")) if first_rows else f"Period {first_order}"
    latest_label = str(latest_rows[0].get("periodLabel", f"Period {latest_order}")) if latest_rows else f"Period {latest_order}"

    first_score = weighted_average(first_rows, "score")
    latest_score = weighted_average(latest_rows, "score")
    course_summaries = summarize_by_course(records, first_order, latest_order)
    lowest_completion = sorted(course_summaries, key=lambda item: item["completion"])[:2]
    strongest_growth = sorted(course_summaries, key=lambda item: item["change"], reverse=True)[:2]
    weakest_skills = summarize_skills(latest_rows)

    return {
        "source": "synthetic public dashboard JSON",
        "synthetic_disclosure": data.get("description", "Synthetic assessment demo data."),
        "period_window": f"{first_label} to {latest_label}",
        "latest_period": latest_label,
        "students_latest_period": int(sum(row.get("students", 0) or 0 for row in latest_rows)),
        "latest_score": round(latest_score, 1),
        "score_change_from_baseline": round(latest_score - first_score, 1),
        "latest_completion": round(weighted_average(latest_rows, "completion"), 1),
        "latest_proficiency": round(weighted_average(latest_rows, "proficiency"), 1),
        "course_summaries": course_summaries,
        "strongest_growth": strongest_growth,
        "lowest_completion": lowest_completion,
        "lowest_skill_signals": weakest_skills,
        "guardrails": [
            "Do not claim this data is real.",
            "Do not identify students, teachers, sections, or schools.",
            "Use the memo as a portfolio demonstration of assessment reporting workflow design.",
        ],
    }


def build_user_prompt(summary: dict[str, Any]) -> str:
    summary_json = json.dumps(summary, indent=2, sort_keys=True)
    return (
        "Draft a department-chair leadership memo from the synthetic assessment "
        "summary below.\n\n"
        "Requirements:\n"
        "- Title the memo.\n"
        "- Start with one sentence stating this is synthetic demo data.\n"
        "- Include three trends, two risks or watch items, and three next actions.\n"
        "- Keep it under 450 words.\n"
        "- Use restrained professional language for school leaders.\n"
        "- Do not invent details beyond the summary.\n\n"
        f"Synthetic summary:\n```json\n{summary_json}\n```"
    )


def build_local_memo(summary: dict[str, Any]) -> str:
    strongest = ", ".join(f"{item['course']} (+{item['change']} pts)" for item in summary["strongest_growth"]) or "no course-level growth summary"
    completion_watch = ", ".join(f"{item['course']} ({item['completion']}%)" for item in summary["lowest_completion"]) or "no completion watch item"
    skill_watch = ", ".join(f"{item['skill']} ({item['signal']:+.1f})" for item in summary["lowest_skill_signals"][:3]) or "no skill watch item"
    return f"""# Synthetic Assessment Leadership Memo Draft

This memo is based on synthetic demo data and does not describe real students, teachers, sections, or a real school.

## Trends

- The synthetic program average is {summary['latest_score']}% in {summary['latest_period']}, a {summary['score_change_from_baseline']:+.1f} point change across {summary['period_window']}.
- Completion is {summary['latest_completion']}% in the latest period, which makes the synthetic dashboard suitable for discussing participation and assessment operations alongside achievement.
- The strongest course-level growth signals are {strongest}, suggesting where a leader might inspect curriculum, pacing, or intervention patterns in a real deployment.

## Risks To Watch

- Completion deserves attention in {completion_watch}; in a real setting, participation gaps would affect interpretation before instructional conclusions are drawn.
- Lower skill signals include {skill_watch}; these should be treated as hypothesis generators rather than final judgments.

## Next Actions

- Review the lowest-completion course groups first so reporting conversations distinguish missing data from performance data.
- Use the lower skill signals to draft short reteaching or remediation checks tied to specific assessment items.
- Pair the dashboard with a written validation note so leaders understand that the public artifact is synthetic and privacy-reviewed.
"""


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a synthetic assessment leadership memo.")
    parser.add_argument(
        "--input",
        default="../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json",
        help="Path to public synthetic dashboard JSON.",
    )
    parser.add_argument(
        "--memo-out",
        default="reports/sample-leadership-memo.md",
        help="Where to write the memo draft.",
    )
    parser.add_argument(
        "--prompt-out",
        default="reports/ai-assessment-memo-prompt.md",
        help="Where to write the prompt preview.",
    )
    parser.add_argument("--env-file", type=Path, help="Optional local env file. Only OpenAI variables are loaded.")
    parser.add_argument("--model", help="OpenAI model to use when --call-api is passed.")
    parser.add_argument(
        "--call-api",
        action="store_true",
        help="Send the synthetic aggregate summary to OpenAI. Default is local dry run.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    data = load_json(Path(args.input))
    summary = build_summary(data)
    user_prompt = build_user_prompt(summary)
    prompt_preview = (
        "# AI Assessment Memo Prompt Preview\n\n"
        "This prompt contains only synthetic public-safe aggregate summary data.\n\n"
        "## System Prompt\n\n"
        f"{SYSTEM_PROMPT}\n\n"
        "## User Prompt\n\n"
        f"{user_prompt}\n"
    )
    write_text(Path(args.prompt_out), prompt_preview)

    if args.call_api:
        config = load_openai_config(args.env_file, args.model)
        memo = call_openai_response(
            api_key=config.api_key,
            model=config.model,
            system_prompt=SYSTEM_PROMPT,
            user_prompt=user_prompt,
            max_output_tokens=1200,
        )
        mode = f"api:{config.model}"
    else:
        memo = build_local_memo(summary)
        mode = "dry-run-local"

    write_text(Path(args.memo_out), memo)
    print(f"mode: {mode}")
    print(f"wrote {args.prompt_out}")
    print(f"wrote {args.memo_out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
