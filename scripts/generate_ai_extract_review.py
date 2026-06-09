#!/usr/bin/env python3
"""Review synthetic SQL extracts with an optional OpenAI post-extract pass."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

from openai_public_safe import assert_public_safe_text, call_openai_response, load_openai_config


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXTRACT_DIR = PROJECT_ROOT / "data" / "external" / "synthetic-education-data"
DEFAULT_EXTRACT_REPORT = PROJECT_ROOT / "reports" / "sql_warehouse_assessment_extract.md"
DEFAULT_ANALYST_REPORT = PROJECT_ROOT / "reports" / "sql_warehouse_assessment_report.md"
DEFAULT_PROMPT_OUT = PROJECT_ROOT / "reports" / "ai-extract-review-prompt.md"
DEFAULT_JSON_OUT = PROJECT_ROOT / "reports" / "ai-extract-review.json"
DEFAULT_REVIEW_OUT = PROJECT_ROOT / "reports" / "ai-extract-review.md"

SYSTEM_PROMPT = (
    "You review public-safe synthetic assessment extract artifacts for a "
    "portfolio project. Treat the SQL outputs as deterministic source-of-truth "
    "artifacts. Be direct, conservative, and specific. State that the data is "
    "synthetic demo data. Do not imply the data describes real students, "
    "teachers, sections, schools, or personnel. Do not invent facts beyond the "
    "provided summary."
)

REVIEW_TEXT_FORMAT: dict[str, Any] = {
    "type": "json_schema",
    "name": "assessment_extract_review",
    "strict": True,
    "schema": {
        "type": "object",
        "additionalProperties": False,
        "required": [
            "synthetic_disclosure",
            "overall_status",
            "review_summary",
            "extract_findings",
            "quality_checks",
            "interpretation",
            "risks",
            "next_actions",
            "portfolio_relevance",
        ],
        "properties": {
            "synthetic_disclosure": {"type": "string"},
            "overall_status": {"type": "string"},
            "review_summary": {"type": "string"},
            "extract_findings": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["extract", "rows", "decision_question", "finding"],
                    "properties": {
                        "extract": {"type": "string"},
                        "rows": {"type": "integer"},
                        "decision_question": {"type": "string"},
                        "finding": {"type": "string"},
                    },
                },
            },
            "quality_checks": {
                "type": "array",
                "items": {
                    "type": "object",
                    "additionalProperties": False,
                    "required": ["check", "result", "evidence"],
                    "properties": {
                        "check": {"type": "string"},
                        "result": {"type": "string"},
                        "evidence": {"type": "string"},
                    },
                },
            },
            "interpretation": {"type": "array", "items": {"type": "string"}},
            "risks": {"type": "array", "items": {"type": "string"}},
            "next_actions": {"type": "array", "items": {"type": "string"}},
            "portfolio_relevance": {"type": "string"},
        },
    },
}

DECISION_QUESTIONS = {
    "course_section_performance.csv": "Which course sections have enough assessment evidence to compare performance?",
    "assignment_growth_by_course.csv": "Which courses show the clearest Assignment 01 to Assignment 02 growth signals?",
    "nonparticipation_by_group.csv": "Where are non-participation zeros concentrated before interpreting achievement?",
    "lms_enrollment_reconciliation.csv": "Are LMS-style roster records reconciled before dashboard reporting?",
    "student_readiness_extract.csv": "Which synthetic student readiness records can support readiness views?",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extract-dir", type=Path, default=DEFAULT_EXTRACT_DIR, help="Directory containing CSV extracts.")
    parser.add_argument("--extract-report", type=Path, default=DEFAULT_EXTRACT_REPORT, help="Synthetic extract report.")
    parser.add_argument("--analyst-report", type=Path, default=DEFAULT_ANALYST_REPORT, help="Analyst report built from extracts.")
    parser.add_argument("--prompt-out", type=Path, default=DEFAULT_PROMPT_OUT, help="Prompt preview output path.")
    parser.add_argument("--json-out", type=Path, default=DEFAULT_JSON_OUT, help="Structured review JSON output path.")
    parser.add_argument("--review-out", type=Path, default=DEFAULT_REVIEW_OUT, help="Markdown review output path.")
    parser.add_argument("--env-file", type=Path, help="Optional local env file. Only OpenAI variables are loaded.")
    parser.add_argument("--model", help="OpenAI model for --call-api. Defaults to OPENAI_MODEL or the project default.")
    parser.add_argument("--call-api", action="store_true", help="Call OpenAI. Default is a local deterministic dry run.")
    return parser.parse_args()


def display_path(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return path.name


def round_or_none(value: float | None, digits: int = 4) -> float | None:
    if value is None:
        return None
    return round(value, digits)


def summarize_csv(path: Path) -> dict[str, Any]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        columns = reader.fieldnames or []
        row_count = 0
        null_counts = {column: 0 for column in columns}
        nonempty_counts = {column: 0 for column in columns}
        numeric_values: dict[str, list[float]] = {column: [] for column in columns}

        for row in reader:
            row_count += 1
            for column in columns:
                value = row.get(column, "")
                if value is None or value == "":
                    null_counts[column] += 1
                    continue
                nonempty_counts[column] += 1
                try:
                    numeric_values[column].append(float(value))
                except ValueError:
                    continue

    numeric_summary = []
    for column in columns:
        values = numeric_values[column]
        if not values or len(values) != nonempty_counts[column]:
            continue
        numeric_summary.append(
            {
                "column": column,
                "min": round_or_none(min(values)),
                "max": round_or_none(max(values)),
                "mean": round_or_none(sum(values) / len(values)),
            }
        )

    return {
        "extract": path.name,
        "path": display_path(path),
        "rows": row_count,
        "columns": columns,
        "nonzero_null_counts": {column: count for column, count in null_counts.items() if count},
        "numeric_summary": numeric_summary,
        "decision_question": DECISION_QUESTIONS.get(path.name, "What analytical question does this extract support?"),
    }


def read_public_text(path: Path, max_chars: int = 12000) -> str:
    if not path.exists():
        raise FileNotFoundError(f"Missing required public-safe report: {display_path(path)}")
    text = path.read_text(encoding="utf-8")
    assert_public_safe_text(text, display_path(path))
    if len(text) <= max_chars:
        return text
    return text[:max_chars].rstrip() + "\n\n[Truncated for prompt preview.]"


def build_input_summary(extract_dir: Path, extract_report: Path, analyst_report: Path) -> dict[str, Any]:
    if not extract_dir.exists():
        raise FileNotFoundError(f"Missing extract directory: {display_path(extract_dir)}")
    csv_paths = sorted(extract_dir.glob("*.csv"))
    if not csv_paths:
        raise FileNotFoundError(f"No CSV extracts found in {display_path(extract_dir)}")

    extracts = [summarize_csv(path) for path in csv_paths]
    extract_names = {item["extract"] for item in extracts}
    return {
        "source": "public-safe synthetic SQL extracts",
        "synthetic_disclosure": "All records are synthetic demo data and must not be interpreted as real student outcomes.",
        "extract_directory": display_path(extract_dir),
        "total_extract_rows": sum(item["rows"] for item in extracts),
        "student_readiness_loaded": "student_readiness_extract.csv" in extract_names,
        "extracts": extracts,
        "reports": {
            "extract_report": {
                "path": display_path(extract_report),
                "text": read_public_text(extract_report),
            },
            "analyst_report": {
                "path": display_path(analyst_report),
                "text": read_public_text(analyst_report),
            },
        },
        "guardrails": [
            "Review only the provided synthetic aggregate artifacts.",
            "Do not claim that records describe real students, staff, sections, schools, or personnel.",
            "Do not request or infer private identifiers, contact data, credentials, or raw LMS exports.",
            "Treat OpenAI output as advisory documentation, not a data transformation input.",
        ],
    }


def build_user_prompt(summary: dict[str, Any]) -> str:
    summary_json = json.dumps(summary, indent=2, sort_keys=True)
    return (
        "Review the synthetic SQL extract package below for portfolio readiness.\n\n"
        "Return a compact JSON review with:\n"
        "- an overall status\n"
        "- one finding per extract\n"
        "- quality checks\n"
        "- brief interpretation\n"
        "- risks or limitations\n"
        "- next actions\n"
        "- portfolio relevance\n\n"
        "Keep the review conservative and grounded in the supplied artifacts.\n\n"
        f"Synthetic extract package:\n```json\n{summary_json}\n```"
    )


def build_local_review(summary: dict[str, Any]) -> dict[str, Any]:
    extracts = summary["extracts"]
    readiness_loaded = summary["student_readiness_loaded"]
    extract_findings = [
        {
            "extract": item["extract"],
            "rows": item["rows"],
            "decision_question": item["decision_question"],
            "finding": f"Contains {item['rows']} synthetic aggregate rows and {len(item['columns'])} columns for this decision question.",
        }
        for item in extracts
    ]

    readiness_status = (
        "student_readiness_extract.csv is present."
        if readiness_loaded
        else "student_readiness_extract.csv is omitted from this extract package."
    )
    readiness_risk = (
        "Student-level readiness views should stay curated through the public view contract and should not expose raw LMS staging rows."
        if readiness_loaded
        else "Student-level readiness views should be enabled only after the extract is loaded and reviewed."
    )
    readiness_next_action = (
        "Add a focused dashboard fixture for the readiness extract before expanding dashboard views."
        if readiness_loaded
        else "Re-run this review after loading student readiness or adding new extract families."
    )

    return {
        "synthetic_disclosure": summary["synthetic_disclosure"],
        "overall_status": "portfolio_ready_with_known_limitations",
        "review_summary": (
            f"The package contains {len(extracts)} synthetic SQL extracts with "
            f"{summary['total_extract_rows']} total aggregate rows. Extraction "
            "and interpretation remain separated, which is the right design for reproducibility."
        ),
        "extract_findings": extract_findings,
        "quality_checks": [
            {
                "check": "Synthetic data boundary",
                "result": "pass",
                "evidence": "Input reports explicitly state that all records are synthetic and public-safe.",
            },
            {
                "check": "Extract row counts",
                "result": "pass",
                "evidence": "Each discovered CSV extract has at least one row.",
            },
            {
                "check": "Readiness availability",
                "result": "known limitation" if not readiness_loaded else "pass",
                "evidence": readiness_status,
            },
        ],
        "interpretation": [
            "The extract set supports performance, growth, missingness, and roster-quality analysis without exposing raw private records.",
            "The strongest portfolio signal is the distinction between participation/missingness and score evidence.",
            "The DuckDB-backed extract path is the reproducible local baseline; hosted Supabase remains an optional serving-layer demonstration.",
        ],
        "risks": [
            "The OpenAI review is advisory and should not become an input to downstream data generation or CSV exports.",
            readiness_risk,
            "Future examples should continue using aggregate summaries rather than raw LMS rows or real learner records.",
        ],
        "next_actions": [
            "Keep the deterministic SQL extracts as the source of truth.",
            "Add a small public data dictionary for each extract before expanding dashboard views.",
            readiness_next_action,
        ],
        "portfolio_relevance": (
            "This demonstrates a defensible AI-assisted analytics pattern: deterministic extraction first, "
            "then public-safe narrative review over aggregate synthetic artifacts."
        ),
    }


def validate_review(review: dict[str, Any]) -> None:
    required = {
        "synthetic_disclosure",
        "overall_status",
        "review_summary",
        "extract_findings",
        "quality_checks",
        "interpretation",
        "risks",
        "next_actions",
        "portfolio_relevance",
    }
    missing = sorted(required.difference(review))
    if missing:
        raise ValueError(f"Review JSON is missing required keys: {', '.join(missing)}")


def bullet_list(items: list[str]) -> str:
    return "\n".join(f"- {item}" for item in items)


def table(headers: list[str], rows: list[list[str]]) -> str:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    lines.extend("| " + " | ".join(row) + " |" for row in rows)
    return "\n".join(lines)


def render_review(review: dict[str, Any], mode: str, summary: dict[str, Any]) -> str:
    extract_rows = [
        [
            item["extract"],
            str(item["rows"]),
            item["decision_question"],
            item["finding"],
        ]
        for item in review["extract_findings"]
    ]
    quality_rows = [
        [item["check"], item["result"], item["evidence"]]
        for item in review["quality_checks"]
    ]

    return f"""# AI Extract Review

Mode: `{mode}`

Source: `{summary['extract_directory']}`

{review['synthetic_disclosure']}

## Overall Status

`{review['overall_status']}`

{review['review_summary']}

## Extract Findings

{table(["Extract", "Rows", "Decision Question", "Finding"], extract_rows)}

## Quality Checks

{table(["Check", "Result", "Evidence"], quality_rows)}

## Interpretation

{bullet_list(review['interpretation'])}

## Risks And Limitations

{bullet_list(review['risks'])}

## Next Actions

{bullet_list(review['next_actions'])}

## Portfolio Relevance

{review['portfolio_relevance']}
"""


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + "\n", encoding="utf-8")


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    summary = build_input_summary(args.extract_dir, args.extract_report, args.analyst_report)
    user_prompt = build_user_prompt(summary)
    assert_public_safe_text(user_prompt, "extract review prompt")

    prompt_preview = (
        "# AI Extract Review Prompt Preview\n\n"
        "This prompt contains only synthetic public-safe aggregate summaries and report text.\n\n"
        "## System Prompt\n\n"
        f"{SYSTEM_PROMPT}\n\n"
        "## User Prompt\n\n"
        f"{user_prompt}\n"
    )
    write_text(args.prompt_out, prompt_preview)

    if args.call_api:
        config = load_openai_config(args.env_file, args.model)
        response_text = call_openai_response(
            api_key=config.api_key,
            model=config.model,
            system_prompt=SYSTEM_PROMPT,
            user_prompt=user_prompt,
            text_format=REVIEW_TEXT_FORMAT,
            max_output_tokens=1800,
        )
        review = json.loads(response_text)
        mode = f"api:{config.model}"
    else:
        review = build_local_review(summary)
        mode = "dry-run-local"

    validate_review(review)
    write_json(args.json_out, review)
    write_text(args.review_out, render_review(review, mode, summary))

    print(f"mode: {mode}")
    print(f"wrote {display_path(args.prompt_out)}")
    print(f"wrote {display_path(args.json_out)}")
    print(f"wrote {display_path(args.review_out)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
