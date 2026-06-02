#!/usr/bin/env python3
"""Validate public synthetic assessment data for privacy and schema risks."""

from __future__ import annotations

import argparse
import json
import re
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REQUIRED_TOP_LEVEL_KEYS = {
    "bootstrap",
    "periods",
    "sections",
    "records",
    "studentRecords",
}

FORBIDDEN_KEY_PATTERNS = [
    re.compile(pattern, re.IGNORECASE)
    for pattern in (
        r"email",
        r"password",
        r"secret",
        r"token",
        r"oauth",
        r"api[_-]?key",
        r"canvas[_-]?(user|course|assignment|submission|url)",
        r"sis",
        r"lms",
        r"submission",
        r"parent",
        r"guardian",
    )
]

FORBIDDEN_VALUE_PATTERNS = [
    ("email address", re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.IGNORECASE)),
    ("web URL", re.compile(r"https?://|www\.", re.IGNORECASE)),
    ("local private path", re.compile(r"/home/[^/]+/repos/private|\\\\Users\\\\", re.IGNORECASE)),
    ("OpenAI-style key", re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b")),
    ("bearer token", re.compile(r"\bBearer\s+[A-Za-z0-9._-]{16,}\b", re.IGNORECASE)),
    ("Canvas reference", re.compile(r"\bcanvas\b", re.IGNORECASE)),
]


@dataclass
class Finding:
    severity: str
    check: str
    detail: str


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def walk_json(value: Any, path: str = "$") -> Iterable[tuple[str, Any]]:
    yield path, value
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk_json(child, f"{path}.{key}")
    elif isinstance(value, list):
        for idx, child in enumerate(value):
            yield from walk_json(child, f"{path}[{idx}]")


def add(findings: list[Finding], severity: str, check: str, detail: str) -> None:
    findings.append(Finding(severity, check, detail))


def check_top_level(data: dict[str, Any], findings: list[Finding]) -> None:
    missing = sorted(REQUIRED_TOP_LEVEL_KEYS - set(data))
    if missing:
        add(findings, "fail", "required keys", f"Missing top-level keys: {', '.join(missing)}")
    else:
        add(findings, "pass", "required keys", "All expected dashboard sections are present.")


def check_forbidden_keys(data: dict[str, Any], findings: list[Finding]) -> None:
    flagged = []
    for path, value in walk_json(data):
        if not isinstance(value, dict):
            continue
        for key in value:
            if any(pattern.search(key) for pattern in FORBIDDEN_KEY_PATTERNS):
                flagged.append(f"{path}.{key}")
    if flagged:
        add(findings, "fail", "forbidden fields", "; ".join(flagged[:20]))
    else:
        add(findings, "pass", "forbidden fields", "No high-risk private-data field names were found.")


def check_forbidden_values(data: dict[str, Any], findings: list[Finding]) -> None:
    flagged = []
    for path, value in walk_json(data):
        if not isinstance(value, str):
            continue
        for label, pattern in FORBIDDEN_VALUE_PATTERNS:
            if pattern.search(value):
                flagged.append(f"{path}: {label}")
    if flagged:
        add(findings, "fail", "forbidden values", "; ".join(flagged[:20]))
    else:
        add(findings, "pass", "forbidden values", "No emails, URLs, tokens, private paths, or Canvas references were found.")


def check_fake_identifiers(data: dict[str, Any], findings: list[Finding]) -> None:
    student_records = data.get("studentRecords", [])
    bad_student_ids = []
    for row in student_records:
        student_id = str(row.get("studentId", ""))
        if not re.fullmatch(r"[a-z0-9-]+-student-\d{2}", student_id):
            bad_student_ids.append(student_id or "[blank]")
    if bad_student_ids:
        add(findings, "fail", "synthetic student ids", f"Unexpected student ID patterns: {bad_student_ids[:10]}")
    else:
        add(findings, "pass", "synthetic student ids", "All student IDs match the generated fake ID pattern.")

    teacher_values = sorted(
        {str(row.get("teacher", "")) for row in data.get("sections", []) + data.get("records", []) if row.get("teacher")}
    )
    bad_teachers = [value for value in teacher_values if not re.fullmatch(r"Teacher [A-Z]", value)]
    if bad_teachers:
        add(findings, "warn", "synthetic teacher labels", f"Teacher labels should be clearly fake: {bad_teachers[:10]}")
    else:
        add(findings, "pass", "synthetic teacher labels", "All teacher labels use public-safe fake labels.")


def check_numeric_bounds(data: dict[str, Any], findings: list[Finding]) -> None:
    bad_scores = []
    bad_completion = []
    for path, value in walk_json(data):
        if path.endswith(".score") or path.endswith(".proficiency") or path.endswith(".completion"):
            if isinstance(value, (int, float)) and not 0 <= float(value) <= 100:
                bad_scores.append(f"{path}={value}")
        if path.endswith(".completion") and isinstance(value, (int, float)) and not 0 <= float(value) <= 100:
            bad_completion.append(f"{path}={value}")
    if bad_scores:
        add(findings, "fail", "percentage bounds", "; ".join(bad_scores[:20]))
    else:
        add(findings, "pass", "percentage bounds", "Scores, proficiency, and completion values are within 0-100.")
    if bad_completion:
        add(findings, "fail", "completion bounds", "; ".join(bad_completion[:20]))


def check_group_sizes(data: dict[str, Any], findings: list[Finding], min_group_size: int) -> None:
    small_sections = [
        f"{section.get('id', '[missing]')} ({section.get('students', 0)})"
        for section in data.get("sections", [])
        if int(section.get("students", 0)) < min_group_size
    ]
    small_records = [
        f"{record.get('id', '[missing]')} ({record.get('students', 0)})"
        for record in data.get("records", [])
        if int(record.get("students", 0)) < min_group_size
    ]
    if small_sections or small_records:
        detail = []
        if small_sections:
            detail.append(f"sections: {', '.join(small_sections[:10])}")
        if small_records:
            detail.append(f"records: {', '.join(small_records[:10])}")
        add(findings, "warn", "minimum group size", "; ".join(detail))
    else:
        add(findings, "pass", "minimum group size", f"All sections and aggregate records meet k >= {min_group_size}.")


def check_bootstrap_disclosure(data: dict[str, Any], findings: list[Finding]) -> None:
    bootstrap = data.get("bootstrap", {})
    source_text = str(bootstrap.get("privateBootstrapSource", ""))
    if "used only to calibrate" in source_text and "no private rows" in source_text:
        add(findings, "pass", "bootstrap disclosure", "Bootstrap disclosure states that private data was used only for calibration.")
    else:
        add(findings, "warn", "bootstrap disclosure", "Add explicit language that private rows and identifiers are excluded.")


def summarize_dataset(data: dict[str, Any]) -> dict[str, int]:
    return {
        "periods": len(data.get("periods", [])),
        "sections": len(data.get("sections", [])),
        "aggregate_records": len(data.get("records", [])),
        "synthetic_student_records": len(data.get("studentRecords", [])),
    }


def validate(data: dict[str, Any], min_group_size: int) -> list[Finding]:
    findings: list[Finding] = []
    check_top_level(data, findings)
    check_forbidden_keys(data, findings)
    check_forbidden_values(data, findings)
    check_fake_identifiers(data, findings)
    check_numeric_bounds(data, findings)
    check_group_sizes(data, findings, min_group_size)
    check_bootstrap_disclosure(data, findings)
    return findings


def write_report(path: Path, input_path: Path, data: dict[str, Any], findings: list[Finding]) -> None:
    counts = summarize_dataset(data)
    fail_count = sum(1 for finding in findings if finding.severity == "fail")
    warn_count = sum(1 for finding in findings if finding.severity == "warn")
    pass_count = sum(1 for finding in findings if finding.severity == "pass")
    status = "PASS" if fail_count == 0 else "FAIL"

    lines = [
        "# Synthetic Data Validation Report",
        "",
        f"Input: `{input_path}`",
        f"Overall status: **{status}**",
        "",
        "## Dataset Summary",
        "",
        f"- Periods: {counts['periods']}",
        f"- Sections: {counts['sections']}",
        f"- Aggregate records: {counts['aggregate_records']}",
        f"- Synthetic student-period records: {counts['synthetic_student_records']}",
        "",
        "## Findings",
        "",
        f"- Pass: {pass_count}",
        f"- Warn: {warn_count}",
        f"- Fail: {fail_count}",
        "",
        "| Severity | Check | Detail |",
        "| --- | --- | --- |",
    ]
    for finding in findings:
        detail = finding.detail.replace("|", "\\|")
        lines.append(f"| {finding.severity.upper()} | {finding.check} | {detail} |")
    lines.append("")
    lines.append("This report validates the public synthetic artifact only. It does not inspect or publish private source exports.")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate public synthetic assessment data.")
    parser.add_argument(
        "--input",
        default="data/synthetic/assessment-dashboard.json",
        help="Path to the public synthetic dashboard JSON.",
    )
    parser.add_argument(
        "--report",
        default="reports/synthetic-data-validation-report.md",
        help="Where to write the markdown validation report.",
    )
    parser.add_argument(
        "--min-group-size",
        type=int,
        default=10,
        help="Minimum displayed section/aggregate group size.",
    )
    parser.add_argument(
        "--fail-on-warn",
        action="store_true",
        help="Exit nonzero on warnings as well as failures.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input)
    if not input_path.exists():
        raise SystemExit(f"Input not found: {input_path}")
    data = load_json(input_path)
    if not isinstance(data, dict):
        raise SystemExit("Input JSON must be an object.")
    findings = validate(data, args.min_group_size)
    report_path = Path(args.report)
    write_report(report_path, input_path, data, findings)
    fail_count = sum(1 for finding in findings if finding.severity == "fail")
    warn_count = sum(1 for finding in findings if finding.severity == "warn")
    print(f"wrote {report_path}")
    print(f"findings: {fail_count} fail, {warn_count} warn")
    if fail_count or (warn_count and args.fail_on_warn):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

