#!/usr/bin/env python3
"""Build the static dashboard JSON from SQL warehouse extract CSVs."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
from datetime import date, datetime, timezone
from pathlib import Path
from statistics import mean
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EXTRACT_DIR = PROJECT_ROOT / "data" / "external" / "education-data-simulation-engine"
DEFAULT_OUTPUT = PROJECT_ROOT / "data" / "synthetic" / "assessment-dashboard.json"
DEFAULT_MANIFEST_OUTPUT = PROJECT_ROOT / "data" / "published" / "assessment-dashboard.manifest.json"
DEFAULT_ITEM_COUNT = 30
FIRST_ACADEMIC_YEAR_START = 2019
DEFAULT_PROFICIENCY_BENCHMARK = 70.0
COURSE_PROFICIENCY_BENCHMARKS = {
    "Algebra 1": 65.0,
    "Geometry": 66.0,
    "Algebra 2": 68.0,
    "Honors Algebra 2": 70.0,
    "Precalculus": 68.0,
    "AP Precalculus": 70.0,
    "AP Calculus AB": 70.0,
    "AP Calculus BC": 72.0,
    "Beyond Core Math Sequence": 75.0,
}
EXTRACT_NAMES = (
    "course_section_performance.csv",
    "assignment_growth_by_course.csv",
    "nonparticipation_by_group.csv",
    "lms_enrollment_reconciliation.csv",
    "student_readiness_extract.csv",
)


def read_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise FileNotFoundError(f"Missing SQL extract file: {path}")
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def csv_row_count(path: Path) -> int:
    with path.open(newline="", encoding="utf-8") as handle:
        return sum(1 for _ in csv.DictReader(handle))


def to_float(value: str | None, default: float = 0.0) -> float:
    if value is None or value == "":
        return default
    try:
        return float(value)
    except ValueError:
        return default


def to_int(value: str | None, default: int = 0) -> int:
    return int(round(to_float(value, float(default))))


def round1(value: float) -> float:
    return round(value, 1)


def slug(value: str) -> str:
    text = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return text or "unknown"


def section_short_label(section_label: str) -> str:
    if " - " in section_label:
        return section_label.split(" - ", 1)[1]
    return section_label


def academic_year_for_order(order: int) -> tuple[int, int, str]:
    start = FIRST_ACADEMIC_YEAR_START + max(0, (order - 1) // 2)
    end = start + 1
    return start, end, f"{start}-{str(end)[-2:]}"


def proficiency_benchmark(course_name: str) -> float:
    return COURSE_PROFICIENCY_BENCHMARKS.get(course_name, DEFAULT_PROFICIENCY_BENCHMARK)


def period_for_assignment(label: str, assessment_window: str, sequence_index: int | None = None) -> dict[str, Any]:
    order = sequence_index if sequence_index is not None else to_int(label.rsplit(" ", 1)[-1], 1)
    season = "Beginning" if assessment_window == "beginning_of_year" else "End"
    window_code = "BOY" if assessment_window == "beginning_of_year" else "EOY"
    academic_year_start, academic_year_end, academic_year = academic_year_for_order(order)
    return {
        "id": slug(label),
        "label": f"{academic_year} {window_code} Standardized Math Assessment",
        "shortLabel": f"{academic_year} {window_code}",
        "sourceLabel": label,
        "year": academic_year_end,
        "academicYear": academic_year,
        "academicYearStart": academic_year_start,
        "academicYearEnd": academic_year_end,
        "windowCode": window_code,
        "season": season,
        "order": order,
        "assessmentWindow": assessment_window,
    }


def unique_periods(performance_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    periods: dict[str, dict[str, Any]] = {}
    for row in performance_rows:
        label = row["assignment_label"]
        periods[label] = period_for_assignment(label, row["assessment_window"], to_int(row.get("sequence_index")))
    return sorted(periods.values(), key=lambda item: item["order"])


def quantile(values: list[float], probability: float) -> float:
    ordered = sorted(value for value in values if value == value)
    if not ordered:
        return 0.0
    index = (len(ordered) - 1) * probability
    lower = int(index)
    upper = min(lower + 1, len(ordered) - 1)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] * (upper - index) + ordered[upper] * (index - lower)


def score_for_assignment(row: dict[str, str], label: str, order: int | None = None) -> float:
    if row.get("boy_assignment_label") == label:
        return to_float(row.get("assignment_01_score"))
    if row.get("eoy_assignment_label") == label:
        return to_float(row.get("assignment_02_score"))
    if order == 1:
        return to_float(row.get("assignment_01_score"))
    if order == 2:
        return to_float(row.get("assignment_02_score"))
    return 0.0


def completed_score(value: float) -> bool:
    return value > 0


def section_readiness(readiness_rows: list[dict[str, str]]) -> dict[str, float]:
    grouped: dict[str, list[float]] = {}
    for row in readiness_rows:
        grouped.setdefault(row["section_id"], []).append(to_float(row.get("posterior_readiness_after_assignment_02")))
    return {section_id: round1(mean(values)) for section_id, values in grouped.items() if values}


def section_proficiency(
    readiness_rows: list[dict[str, str]],
    section_id: str,
    label: str,
    order: int,
    course_name: str,
) -> float:
    scores = [
        score_for_assignment(row, label, order)
        for row in readiness_rows
        if row["section_id"] == section_id
    ]
    present_scores = [score for score in scores if completed_score(score)]
    if not present_scores:
        return 0.0
    benchmark = proficiency_benchmark(course_name)
    return round1(100 * sum(score >= benchmark for score in present_scores) / len(present_scores))


def build_sections(
    performance_rows: list[dict[str, str]],
    readiness_rows: list[dict[str, str]],
) -> list[dict[str, Any]]:
    by_section: dict[str, list[dict[str, str]]] = {}
    for row in performance_rows:
        by_section.setdefault(row["section_id"], []).append(row)

    readiness_by_section: dict[str, list[dict[str, str]]] = {}
    for row in readiness_rows:
        readiness_by_section.setdefault(row["section_id"], []).append(row)

    readiness = section_readiness(readiness_rows)
    sections = []
    for section_id, rows in sorted(by_section.items()):
        ordered = sorted(rows, key=lambda row: to_int(row["sequence_index"]))
        first = ordered[0]
        latest = ordered[-1]
        student_rows = readiness_by_section.get(section_id, [])
        grade = student_rows[0]["grade_level"] if student_rows else ""
        baseline = to_float(first.get("avg_present_score"))
        latest_score = to_float(latest.get("avg_present_score"))
        completion = round1(100 * (1 - to_float(latest.get("nonparticipation_rate"))))
        proficiency = section_proficiency(
            readiness_rows,
            section_id,
            latest["assignment_label"],
            to_int(latest["sequence_index"]),
            first["course_name"],
        )
        sections.append(
            {
                "id": section_id,
                "course": first["course_name"],
                "grade": grade,
                "teacher": first["teacher_label"],
                "section": section_short_label(first["section_label"]),
                "students": to_int(latest.get("enrolled_students")),
                "baseline": round1(baseline),
                "growth": round1(latest_score - baseline),
                "springLift": round1(latest_score - baseline),
                "courseTrack": first["course_track"],
                "skills": {
                    "Score": round1(latest_score),
                    "Proficiency": proficiency,
                    "Completion": completion,
                    "Readiness": readiness.get(section_id, 0.0),
                },
            }
        )
    return sections


def build_records(
    performance_rows: list[dict[str, str]],
    readiness_rows: list[dict[str, str]],
) -> list[dict[str, Any]]:
    baseline_by_section = {
        row["section_id"]: to_float(row.get("avg_present_score"))
        for row in performance_rows
        if row["assignment_label"] == "Assignment 01"
    }
    readiness = section_readiness(readiness_rows)
    grade_by_section = {
        row["section_id"]: row["grade_level"]
        for row in readiness_rows
    }

    records = []
    for row in sorted(performance_rows, key=lambda item: (item["section_id"], to_int(item["sequence_index"]))):
        order = to_int(row["sequence_index"])
        period = period_for_assignment(row["assignment_label"], row["assessment_window"], order)
        score = to_float(row.get("avg_present_score"))
        students = to_int(row.get("enrolled_students"))
        completed = to_int(row.get("present_students"))
        completion = round1(100 * (1 - to_float(row.get("nonparticipation_rate"))))
        proficiency = section_proficiency(
            readiness_rows,
            row["section_id"],
            row["assignment_label"],
            order,
            row["course_name"],
        )
        growth = round1(score - baseline_by_section.get(row["section_id"], score))
        records.append(
            {
                "id": f"{row['section_id']}-{period['id']}",
                "sectionId": row["section_id"],
                "course": row["course_name"],
                "grade": grade_by_section.get(row["section_id"], ""),
                "teacher": row["teacher_label"],
                "section": section_short_label(row["section_label"]),
                "periodId": period["id"],
                "periodLabel": period["label"],
                "year": period["year"],
                "season": period["season"],
                "order": period["order"],
                "students": students,
                "completed": completed,
                "notCompleted": max(0, students - completed),
                "score": round1(score),
                "proficiency": proficiency,
                "completion": completion,
                "growth": growth,
                "rawMean": round(score * DEFAULT_ITEM_COUNT / 100, 2),
                "itemCount": DEFAULT_ITEM_COUNT,
                "courseTrack": row["course_track"],
                "skills": {
                    "Score": round1(score),
                    "Proficiency": proficiency,
                    "Completion": completion,
                    "Readiness": readiness.get(row["section_id"], 0.0),
                },
            }
        )
    return records


def build_student_records(readiness_rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    records = []
    section_counts: dict[str, int] = {}
    for row in sorted(readiness_rows, key=lambda item: (item["section_id"], to_int(item["student_dim_id"]))):
        section_id = row["section_id"]
        section_counts[section_id] = section_counts.get(section_id, 0) + 1
        student_id = f"{slug(section_id)}-student-{section_counts[section_id]:02d}"
        assignments = (
            (row.get("boy_assignment_label", "Assignment 01"), "beginning_of_year", 1),
            (row.get("eoy_assignment_label", "Assignment 02"), "end_of_year", 2),
        )
        for label, assessment_window, fallback_order in assignments:
            period = period_for_assignment(label, assessment_window, to_int(label.rsplit(" ", 1)[-1], fallback_order))
            score = score_for_assignment(row, label, period["order"])
            records.append(
                {
                    "id": f"{student_id}-{period['id']}",
                    "studentId": student_id,
                    "sectionId": section_id,
                    "course": row["course_name"],
                    "grade": row["grade_level"],
                    "teacher": row["teacher_label"],
                    "section": section_short_label(row["section_label"]),
                    "periodId": period["id"],
                    "periodLabel": period["label"],
                    "year": period["year"],
                    "season": period["season"],
                    "order": period["order"],
                    "completed": completed_score(score),
                    "rawScore": round(score * DEFAULT_ITEM_COUNT / 100),
                    "itemCount": DEFAULT_ITEM_COUNT,
                    "score": round1(score),
                    "courseTrack": row["course_track"],
                    "attendanceCategory": row["attendance_category"],
                    "readiness": round1(to_float(row.get("posterior_readiness_after_assignment_02"))),
                }
            )
    return records


def build_bands(student_records: list[dict[str, Any]], periods: list[dict[str, Any]]) -> dict[str, Any]:
    department_lower = []
    department_upper = []
    network_lower = []
    network_upper = []
    for period in periods:
        rows = [row for row in student_records if row["periodId"] == period["id"]]
        completed_scores = [row["score"] for row in rows if row["completed"]]
        assigned_scores = [row["score"] for row in rows]
        department_lower.append(round1(quantile(completed_scores, 0.2)))
        department_upper.append(round1(quantile(completed_scores, 0.8)))
        network_lower.append(round1(quantile(assigned_scores, 0.1)))
        network_upper.append(round1(quantile(assigned_scores, 0.9)))
    return {
        "department": {
            "label": "Completed-score p20-p80 band from SQL student readiness extract",
            "lower": department_lower,
            "upper": department_upper,
        },
        "network": {
            "label": "Assigned-score p10-p90 band from SQL student readiness extract",
            "lower": network_lower,
            "upper": network_upper,
        },
        "mastery": {
            "label": "Program reference benchmark",
            "line": [DEFAULT_PROFICIENCY_BENCHMARK for _ in periods],
            "byCourse": {
                course: proficiency_benchmark(course)
                for course in sorted({row["course"] for row in student_records})
            },
            "method": (
                "Synthetic course-level cut scores reflect expected sequence attainment; Beyond Core Math "
                "Sequence has the highest cut score because it represents study after the core sequence. "
                "These illustrative values are not policy or validation thresholds."
            ),
        },
    }


def completion_rates(records: list[dict[str, Any]], periods: list[dict[str, Any]]) -> list[float]:
    rates = []
    for period in periods:
        rows = [row for row in records if row["periodId"] == period["id"]]
        students = sum(row["students"] for row in rows)
        completed = sum(row["completed"] for row in rows)
        rates.append(round1(100 * completed / students) if students else 0.0)
    return rates


def normalize_generated_date(value: str) -> str:
    try:
        parsed = date.fromisoformat(value)
    except ValueError as error:
        raise ValueError(f"Invalid generated date {value!r}; expected YYYY-MM-DD") from error
    if parsed.isoformat() != value:
        raise ValueError(f"Invalid generated date {value!r}; expected YYYY-MM-DD")
    return value


def normalize_generated_at(value: str) -> str:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise ValueError(
            f"Invalid generated timestamp {value!r}; expected UTC ISO 8601"
        ) from error
    if parsed.tzinfo is None:
        raise ValueError(f"Invalid generated timestamp {value!r}; timezone is required")
    normalized = (
        parsed.astimezone(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )
    if normalized != value:
        raise ValueError(
            f"Invalid generated timestamp {value!r}; expected normalized UTC ISO 8601"
        )
    return normalized


def build_dashboard(extract_dir: Path, generated_date: str | None = None) -> dict[str, Any]:
    files = {name: extract_dir / name for name in EXTRACT_NAMES}
    performance_rows = read_rows(files["course_section_performance.csv"])
    growth_rows = read_rows(files["assignment_growth_by_course.csv"])
    missingness_rows = read_rows(files["nonparticipation_by_group.csv"])
    reconciliation_rows = read_rows(files["lms_enrollment_reconciliation.csv"])
    readiness_rows = read_rows(files["student_readiness_extract.csv"])

    periods = unique_periods(performance_rows)
    sections = build_sections(performance_rows, readiness_rows)
    records = build_records(performance_rows, readiness_rows)
    student_records = build_student_records(readiness_rows)

    return {
        "generated": normalize_generated_date(generated_date or date.today().isoformat()),
        "source": {
            "project": "assessment-intelligence",
            "upstreamProject": "education-data-simulation-engine",
            "pipeline": "make dashboard-sync",
            "builder": "scripts/build_sql_dashboard_json.py",
            "extractDir": rel(extract_dir),
            "contract": "sql-extract-dashboard-json-v1",
            "dataClass": "public-safe synthetic SQL warehouse extracts",
            "skillMode": "absolute",
            "assessmentContext": {
                "name": "Synthetic standardized mathematics assessment",
                "academicYears": "2019-20 through 2025-26",
                "windows": ["BOY", "EOY"],
                "scoreScale": "0-100 percent correct",
                "benchmarkType": "synthetic course-specific proficiency cut score",
            },
            "privacyDisclosure": "Generated from public-safe synthetic SQL warehouse extracts; no private rows, identifiers, or school records are included.",
            "recordCounts": {
                "periods": len(periods),
                "sections": len(sections),
                "aggregateRecords": len(records),
                "syntheticStudentRecords": len(student_records),
                "courseSectionPerformanceRows": len(performance_rows),
                "courseGrowthRows": len(growth_rows),
                "nonparticipationRows": len(missingness_rows),
                "rosterReconciliationRows": len(reconciliation_rows),
                "studentReadinessRows": len(readiness_rows),
            },
            "extractFiles": sorted(files),
        },
        "description": (
            "Seven synthetic academic years of BOY and EOY standardized mathematics assessment "
            "data generated from the same SQL warehouse extracts used by assessment-intelligence "
            "report artifacts. No real students, rosters, teachers, sections, IDs, emails, grades, "
            "submissions, or school records are included."
        ),
        "bootstrap": {
            "privateBootstrapSource": (
                "The dashboard is generated from public-safe synthetic SQL warehouse extracts; "
                "no private rows or identifiers are included."
            ),
            "scoreColumnPublicName": "Present assessment score",
            "syntheticItemCount": DEFAULT_ITEM_COUNT,
            "zeroPolicy": "Non-participation zeros remain separated through SQL missingness extracts and completion fields.",
            "completionRatesByPeriod": completion_rates(records, periods),
            "privateDistributionShape": {
                "nonZeroValuesUsedForCalibration": sum(1 for row in student_records if row["score"] > 0),
                "zeroValuesUsedForCompletionModeling": sum(1 for row in student_records if row["score"] <= 0),
            },
        },
        "periods": periods,
        "bands": build_bands(student_records, periods),
        "sections": sections,
        "records": records,
        "studentRecords": student_records,
    }


def build_publication_manifest(
    dashboard: dict[str, Any],
    dashboard_bytes: bytes,
    extract_dir: Path,
    generated_at: str | None = None,
) -> dict[str, Any]:
    extracts = []
    for name in EXTRACT_NAMES:
        extract_path = extract_dir / name
        extract_bytes = extract_path.read_bytes()
        extracts.append(
            {
                "name": name,
                "rows": csv_row_count(extract_path),
                "sha256": sha256_bytes(extract_bytes),
            }
        )

    builder_path = Path(__file__).resolve()
    return {
        "schemaVersion": "assessment-dashboard-manifest-v1",
        "contract": dashboard["source"]["contract"],
        "generatedAt": normalize_generated_at(
            generated_at
            or datetime.now(timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z")
        ),
        "dashboard": {
            "path": "data/synthetic/assessment-dashboard.json",
            "generatedDate": dashboard["generated"],
            "bytes": len(dashboard_bytes),
            "sha256": sha256_bytes(dashboard_bytes),
            "recordCounts": dashboard["source"]["recordCounts"],
        },
        "builder": {
            "path": rel(builder_path),
            "sha256": sha256_bytes(builder_path.read_bytes()),
        },
        "extracts": extracts,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build static dashboard JSON from SQL extract CSVs.")
    parser.add_argument("--extract-dir", type=Path, default=DEFAULT_EXTRACT_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--pages-output", type=Path)
    parser.add_argument("--manifest-output", type=Path, default=DEFAULT_MANIFEST_OUTPUT)
    parser.add_argument("--pages-manifest-output", type=Path)
    parser.add_argument(
        "--generated-date",
        help="Reproducible dashboard date in YYYY-MM-DD format (defaults to today).",
    )
    parser.add_argument(
        "--generated-at",
        help="Reproducible manifest timestamp in normalized UTC ISO 8601 format.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    dashboard = build_dashboard(args.extract_dir, args.generated_date)
    dashboard_bytes = (json.dumps(dashboard, indent=2) + "\n").encode("utf-8")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(dashboard_bytes)
    print(f"wrote {rel(args.output)}")
    if args.pages_output:
        args.pages_output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(args.output, args.pages_output)
        print(f"synced dashboard JSON to {args.pages_output}")

    manifest = build_publication_manifest(
        dashboard,
        dashboard_bytes,
        args.extract_dir,
        args.generated_at,
    )
    manifest_bytes = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    args.manifest_output.parent.mkdir(parents=True, exist_ok=True)
    args.manifest_output.write_bytes(manifest_bytes)
    print(f"wrote {rel(args.manifest_output)}")
    if args.pages_manifest_output:
        args.pages_manifest_output.parent.mkdir(parents=True, exist_ok=True)
        args.pages_manifest_output.write_bytes(manifest_bytes)
        print(f"synced dashboard manifest to {args.pages_manifest_output}")


if __name__ == "__main__":
    main()
