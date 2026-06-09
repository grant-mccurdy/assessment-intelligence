#!/usr/bin/env python3
"""Generate an analyst-facing report from SQL warehouse extracts."""

from __future__ import annotations

import argparse
import csv
from collections import Counter, defaultdict
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXTRACT_DIR = PROJECT_ROOT / "data" / "external" / "synthetic-education-data"
DEFAULT_REPORT_PATH = PROJECT_ROOT / "reports" / "sql_warehouse_assessment_report.md"


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def to_float(value: str | None) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except ValueError:
        return None


def mean(values: list[float]) -> float | None:
    if not values:
        return None
    return sum(values) / len(values)


def format_number(value: float | None, digits: int = 2) -> str:
    if value is None:
        return "n/a"
    return f"{value:.{digits}f}"


def format_rate(value: float | None) -> str:
    if value is None:
        return "n/a"
    return f"{value * 100:.1f}%"


def table(headers: list[str], rows: list[list[str]]) -> str:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    lines.extend("| " + " | ".join(row) + " |" for row in rows)
    return "\n".join(lines)


def rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def build_report(extract_dir: Path) -> str:
    required_files = {
        "course_section_performance": extract_dir / "course_section_performance.csv",
        "assignment_growth_by_course": extract_dir / "assignment_growth_by_course.csv",
        "nonparticipation_by_group": extract_dir / "nonparticipation_by_group.csv",
        "lms_enrollment_reconciliation": extract_dir / "lms_enrollment_reconciliation.csv",
    }
    optional_files = {
        "student_readiness_extract": extract_dir / "student_readiness_extract.csv",
    }
    files = {
        **required_files,
        **{name: path for name, path in optional_files.items() if path.exists()},
    }

    missing = [path for path in required_files.values() if not path.exists()]
    if missing:
        missing_list = ", ".join(rel(path) for path in missing)
        raise FileNotFoundError(f"Missing SQL extract files: {missing_list}")

    performance = read_rows(files["course_section_performance"])
    growth = read_rows(files["assignment_growth_by_course"])
    missingness = read_rows(files["nonparticipation_by_group"])
    reconciliation = read_rows(files["lms_enrollment_reconciliation"])
    readiness = read_rows(files["student_readiness_extract"]) if "student_readiness_extract" in files else []

    extract_rows = [[f"`{path.name}`", str(len(read_rows(path)))] for path in files.values()]

    growth_ranked = sorted(
        growth,
        key=lambda row: to_float(row.get("avg_observed_growth_delta")) or -999,
        reverse=True,
    )
    growth_table = [
        [
            row["grade_level"],
            row["course_name"],
            row["course_track"],
            row["matched_students"],
            format_number(to_float(row.get("assignment_01_avg"))),
            format_number(to_float(row.get("assignment_02_avg"))),
            format_number(to_float(row.get("avg_observed_growth_delta"))),
        ]
        for row in growth_ranked[:6]
    ]

    nonparticipation_ranked = sorted(
        missingness,
        key=lambda row: to_float(row.get("nonparticipation_rate")) or -1,
        reverse=True,
    )
    missingness_table = [
        [
            row["assignment_label"],
            row["grade_level"],
            row["attendance_category"],
            row["course_track"],
            row["student_assignment_rows"],
            row["nonparticipation_zero_rows"],
            format_rate(to_float(row.get("nonparticipation_rate"))),
        ]
        for row in nonparticipation_ranked[:6]
    ]

    status_counts = Counter(row["reconciliation_status"] for row in reconciliation)
    reconciliation_table = [
        [status, str(count)]
        for status, count in sorted(status_counts.items(), key=lambda item: item[0])
    ]

    readiness_table = []
    if readiness:
        readiness_by_track: dict[str, list[float]] = defaultdict(list)
        growth_by_track: dict[str, list[float]] = defaultdict(list)
        for row in readiness:
            readiness_value = to_float(row.get("posterior_readiness_after_assignment_02"))
            growth_value = to_float(row.get("observed_growth_delta"))
            track = row["course_track"]
            if readiness_value is not None:
                readiness_by_track[track].append(readiness_value)
            if growth_value is not None:
                growth_by_track[track].append(growth_value)

        readiness_table = [
            [
                track,
                str(len(readiness_by_track[track])),
                format_number(mean(readiness_by_track[track])),
                format_number(mean(growth_by_track[track])),
            ]
            for track in sorted(readiness_by_track)
        ]

    populated_rows = performance
    assignment_count = len({row["assignment_label"] for row in populated_rows})
    avg_section_score = mean(
        [
            value
            for value in (to_float(row.get("avg_present_score")) for row in populated_rows)
            if value is not None
        ]
    )
    avg_nonparticipation = mean(
        [
            value
            for value in (to_float(row.get("nonparticipation_rate")) for row in populated_rows)
            if value is not None
        ]
    )
    matched_enrollment_rows = sum(int(row["enrollment_rows"]) for row in reconciliation if row["reconciliation_status"] == "matched")
    total_enrollment_rows = sum(int(row["enrollment_rows"]) for row in reconciliation)

    readiness_summary = (
        f"The current SQL-backed extract set contains {len(readiness)} synthetic student readiness records across {len(reconciliation)} course-section roster groups."
        if readiness
        else f"The current SQL-backed extract set contains aggregate and roster-quality extracts across {len(reconciliation)} course-section roster groups; student readiness is omitted in this extract set."
    )
    readiness_section = (
        "## Readiness By Track\n\n"
        + table(["Track", "Records With Readiness", "Avg Posterior Readiness", "Avg Observed Growth"], readiness_table)
        + "\n"
        if readiness_table
        else "## Readiness By Track\n\nStudent-level readiness is not included in this extract set.\n"
    )

    report = f"""# SQL Warehouse Assessment Report

## Purpose

This report turns the synthetic SQL extracts into an analyst-facing assessment brief for `assessment-intelligence`. It verifies that the repo can consume SQL-backed marts from `synthetic-education-data` and use them for performance, growth, missingness, readiness when available, and LMS roster quality analysis.

## Source Extracts

{table(["Extract", "Rows"], extract_rows)}

## Executive Summary

- {readiness_summary}
- The populated extract contains {assignment_count} assessment windows, with an average section-level present-student score of {format_number(avg_section_score)}.
- Average section-level non-participation across populated assessment windows is {format_rate(avg_nonparticipation)}, preserving the distinction between attendance/non-participation and academic score evidence.
- LMS-style roster reconciliation is {matched_enrollment_rows} / {total_enrollment_rows} matched enrollment rows before downstream reporting.

## Highest Observed Growth By Course

{table(["Grade", "Course", "Track", "Matched Students", "Assignment 01 Avg", "Assignment 02 Avg", "Avg Delta"], growth_table)}

## Highest Non-Participation Groups

{table(["Assignment", "Grade", "Attendance", "Track", "Rows", "Zeros", "Rate"], missingness_table)}

{readiness_section}
## LMS Roster Reconciliation

{table(["Status", "Course-Section Groups"], reconciliation_table)}

## Dashboard And Reporting Uses

- Course-section performance views can be built from `course_section_performance.csv`.
- Growth diagnostics can use `assignment_growth_by_course.csv` first, then section-level extracts as the dashboard matures.
- Attendance and missingness views should use `nonparticipation_by_group.csv` so observed zeros are not treated as academic evidence.
- Data-quality cards can use `lms_enrollment_reconciliation.csv` to show whether LMS-derived rosters are reportable.
- Student-level readiness views should use `student_readiness_extract.csv` only when that optional extract is present.

## Limitations

- The current public build contains {assignment_count} populated assessment windows exported from the synthetic warehouse marts.
- The hosted Supabase extract path reads selected public views from the synthetic warehouse; base `lms` and `analytics` tables remain outside the public API contract.
- All records are synthetic and public-safe. This report must not be interpreted as containing real student outcomes.
"""

    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate SQL warehouse assessment report.")
    parser.add_argument("--extract-dir", type=Path, default=DEFAULT_EXTRACT_DIR)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT_PATH)
    args = parser.parse_args()

    report = build_report(args.extract_dir)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(report, encoding="utf-8")
    print(f"Wrote {rel(args.report)}")


if __name__ == "__main__":
    main()
