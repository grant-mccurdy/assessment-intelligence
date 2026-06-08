#!/usr/bin/env python3
"""Extract assessment-analysis datasets from synthetic education SQL sources."""

from __future__ import annotations

import argparse
import csv
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WAREHOUSE = ROOT.parent / "synthetic-education-data/warehouse/synthetic_math.duckdb"
DEFAULT_DUCKDB_OUTPUT_DIR = ROOT / "data/external/synthetic-education-data"
DEFAULT_SUPABASE_OUTPUT_DIR = ROOT / "data/external/synthetic-education-data-supabase"
DEFAULT_ENV_FILE = ROOT.parent.parent / ".env"
EXTRACT_SQL_DIR = ROOT / "sql/extracts"
POSTGRES_EXTRACT_SQL_DIR = ROOT / "sql/extracts_postgres"
DUCKDB_REPORT_PATH = ROOT / "reports/sql_warehouse_assessment_extract.md"
SUPABASE_REPORT_PATH = ROOT / "reports/supabase_assessment_extract.md"
SUPABASE_PROJECT_NAME = "synthetic-education-data"
SUPABASE_API_BASE = "https://api.supabase.com"


@dataclass(frozen=True)
class SupabaseViewExtract:
    extract_name: str
    view_name: str
    order_columns: tuple[str, ...]

    @property
    def csv_name(self) -> str:
        return f"{self.extract_name}.csv"


SUPABASE_VIEW_EXTRACTS = (
    SupabaseViewExtract(
        "course_section_performance",
        "course_section_performance",
        ("course_id", "section_id", "sequence_index"),
    ),
    SupabaseViewExtract(
        "assignment_growth_by_course",
        "assignment_growth_by_course",
        ("grade_level", "course_id"),
    ),
    SupabaseViewExtract(
        "nonparticipation_by_group",
        "nonparticipation_by_group",
        ("assignment_label", "grade_level", "attendance_category", "course_track"),
    ),
    SupabaseViewExtract(
        "lms_enrollment_reconciliation",
        "lms_enrollment_reconciliation",
        ("course_id", "section_id", "reconciliation_status"),
    ),
    SupabaseViewExtract(
        "student_readiness_extract",
        "student_readiness_extract",
        ("grade_level", "course_id", "sis_user_id"),
    ),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        choices=("duckdb", "supabase"),
        default="duckdb",
        help="SQL source to query. DuckDB remains the default reproducible local source.",
    )
    parser.add_argument("--warehouse", type=Path, default=DEFAULT_WAREHOUSE, help="Path to synthetic_math.duckdb.")
    parser.add_argument("--output-dir", type=Path, help="Directory for exported SQL extracts.")
    parser.add_argument("--report-path", type=Path, help="Markdown report path to write.")
    parser.add_argument("--env-file", type=Path, default=DEFAULT_ENV_FILE, help="Local .env file for Supabase credentials.")
    parser.add_argument(
        "--supabase-access-mode",
        choices=("data-api", "management-sql"),
        default="data-api",
        help="Use public Supabase Data API views by default; Management SQL is a local debugging fallback.",
    )
    parser.add_argument("--supabase-project-name", default=SUPABASE_PROJECT_NAME, help="Supabase project name to query.")
    parser.add_argument("--supabase-project-ref", help="Optional Supabase project ref. If omitted, the project name is used.")
    parser.add_argument(
        "--skip-readiness",
        action="store_true",
        help="Skip student_readiness_extract for compatibility with older hosted loads.",
    )
    return parser.parse_args()


def require_warehouse(path: Path) -> None:
    if not path.exists():
        raise SystemExit(
            f"Warehouse not found: {path}\n"
            "Build it first with: cd ../synthetic-education-data && make warehouse"
        )


def extract_name(path: Path) -> str:
    return path.stem.split("_", 1)[1]


def escaped_sql_path(path: Path) -> str:
    return str(path).replace("'", "''")


def read_extract_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


def write_rows(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fieldnames = list(rows[0].keys()) if rows else []
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def scalar(connection: Any, query: str) -> Any:
    return connection.execute(query).fetchone()[0]


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        try:
            return str(path.relative_to(ROOT.parent))
        except ValueError:
            return str(path)


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("export "):
            line = line[len("export "):].strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def source_defaults(source: str) -> tuple[Path, Path]:
    if source == "supabase":
        return DEFAULT_SUPABASE_OUTPUT_DIR, SUPABASE_REPORT_PATH
    return DEFAULT_DUCKDB_OUTPUT_DIR, DUCKDB_REPORT_PATH


def duckdb_summary(connection: Any) -> dict[str, Any]:
    return {
        "source_label": "DuckDB warehouse",
        "students": scalar(connection, "SELECT COUNT(*) FROM mart.dim_student"),
        "courses": scalar(connection, "SELECT COUNT(*) FROM mart.dim_course"),
        "sections": scalar(connection, "SELECT COUNT(*) FROM mart.dim_section"),
        "teachers": scalar(connection, "SELECT COUNT(*) FROM mart.dim_teacher"),
        "assignments": scalar(connection, "SELECT COUNT(*) FROM mart.dim_assignment"),
        "assessment_score_facts": scalar(connection, "SELECT COUNT(*) FROM mart.fact_assessment_score"),
        "lms_enrollment_facts": scalar(connection, "SELECT COUNT(*) FROM mart.fact_lms_enrollment"),
        "validation_checks": scalar(connection, "SELECT COUNT(*) FROM mart.validation_summary"),
        "validation_passes": scalar(connection, "SELECT COUNT(*) FROM mart.validation_summary WHERE status = 'pass'"),
        "matched_rosters": scalar(connection, "SELECT COUNT(*) FROM mart.fact_lms_enrollment WHERE reconciliation_status = 'matched'"),
    }


class SupabaseManagementSqlClient:
    def __init__(self, access_token: str, project_ref: str) -> None:
        self.project_ref = project_ref
        self.headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }

    def query(self, sql: str) -> list[dict[str, Any]]:
        try:
            import requests
        except ImportError as exc:
            raise SystemExit(
                "requests is required for Supabase extraction. Install it with: make analytics-install"
            ) from exc

        response = requests.post(
            f"{SUPABASE_API_BASE}/v1/projects/{self.project_ref}/database/query/read-only",
            headers=self.headers,
            json={"query": sql},
            timeout=60,
        )
        if not response.ok:
            raise SystemExit(
                f"Supabase read-only query failed with status {response.status_code}: "
                f"{response.text[:300]}"
            )
        payload = response.json()
        if not isinstance(payload, list):
            raise SystemExit("Supabase read-only query returned an unexpected response shape.")
        return payload

    def scalar(self, sql: str) -> Any:
        rows = self.query(sql)
        if not rows:
            return None
        return next(iter(rows[0].values()))


class SupabaseDataApiClient:
    def __init__(self, url: str, publishable_key: str) -> None:
        try:
            import requests
        except ImportError as exc:
            raise SystemExit(
                "requests is required for Supabase extraction. Install it with: make analytics-install"
            ) from exc

        self.requests = requests
        self.url = url.rstrip("/")
        self.headers = {
            "apikey": publishable_key,
            "Accept": "application/json",
        }

    def fetch_view(self, view_name: str) -> list[dict[str, Any]]:
        response = self.requests.get(
            f"{self.url}/rest/v1/{view_name}",
            headers=self.headers,
            params={"select": "*", "limit": "10000"},
            timeout=60,
        )
        if not response.ok:
            raise SystemExit(
                f"Supabase Data API view read failed for {view_name!r} "
                f"with status {response.status_code}: {response.text[:300]}"
            )
        payload = response.json()
        if not isinstance(payload, list):
            raise SystemExit(
                f"Supabase Data API view {view_name!r} returned an unexpected response shape."
            )
        return payload


def find_supabase_project_ref(access_token: str, project_name: str) -> str:
    try:
        import requests
    except ImportError as exc:
        raise SystemExit(
            "requests is required for Supabase extraction. Install it with: make analytics-install"
        ) from exc

    response = requests.get(
        f"{SUPABASE_API_BASE}/v1/projects",
        headers={"Authorization": f"Bearer {access_token}"},
        timeout=30,
    )
    if not response.ok:
        raise SystemExit(f"Could not list Supabase projects: status {response.status_code}")
    for project in response.json():
        if project.get("name") == project_name:
            return project["id"]
    raise SystemExit(f"Supabase project not found by name: {project_name}")


def supabase_summary(client: SupabaseManagementSqlClient) -> dict[str, Any]:
    return {
        "source_label": "Supabase Management API analytics schema fallback",
        "students": client.scalar("SELECT COUNT(*)::bigint FROM analytics.dim_student"),
        "courses": client.scalar("SELECT COUNT(*)::bigint FROM analytics.dim_course"),
        "sections": client.scalar("SELECT COUNT(*)::bigint FROM analytics.dim_section"),
        "teachers": client.scalar("SELECT COUNT(*)::bigint FROM analytics.dim_teacher"),
        "assignments": client.scalar("SELECT COUNT(*)::bigint FROM analytics.dim_assignment"),
        "assessment_score_facts": client.scalar("SELECT COUNT(*)::bigint FROM analytics.fact_assessment_score"),
        "lms_enrollment_facts": client.scalar("SELECT COUNT(*)::bigint FROM analytics.fact_lms_enrollment"),
        "validation_checks": client.scalar("SELECT COUNT(*)::bigint FROM analytics.validation_summary"),
        "validation_passes": client.scalar("SELECT COUNT(*)::bigint FROM analytics.validation_summary WHERE status = 'pass'"),
        "matched_rosters": client.scalar("SELECT COUNT(*)::bigint FROM analytics.fact_lms_enrollment WHERE reconciliation_status = 'matched'"),
    }


def data_api_summary(client: SupabaseDataApiClient) -> dict[str, Any]:
    rows = client.fetch_view("warehouse_summary")
    values = {str(row["metric"]): int(row["value"]) for row in rows}
    return {
        "source_label": "Supabase public Data API views",
        "students": values.get("students", 0),
        "courses": values.get("courses", 0),
        "sections": values.get("sections", 0),
        "teachers": values.get("teachers", 0),
        "assignments": values.get("assignments", 0),
        "assessment_score_facts": values.get("assessment_score_facts", 0),
        "lms_enrollment_facts": values.get("lms_enrollment_facts", 0),
        "student_readiness_records": values.get("student_readiness_records", 0),
        "validation_checks": values.get("validation_checks", 0),
        "validation_passes": values.get("validation_passes", 0),
        "matched_rosters": values.get("matched_rosters", 0),
    }


def write_report(
    report_path: Path,
    source_description: str,
    output_dir: Path,
    extract_paths: list[Path],
    summary: dict[str, Any],
) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S %Z")

    lines = [
        "# SQL Warehouse Assessment Extract",
        "",
        f"Generated: {generated_at}",
        "",
        f"Source: {source_description}",
        "",
        f"Extract output directory: `{display_path(output_dir)}`",
        "",
        "## Purpose",
        "",
        "This report verifies that `assessment-intelligence` can query public-safe synthetic marts from `synthetic-education-data` and produce SQL-backed assessment-analysis extracts.",
        "",
        "## Warehouse Summary",
        "",
        "| Metric | Value |",
        "| --- | ---: |",
        f"| Students | {summary['students']} |",
        f"| Courses | {summary['courses']} |",
        f"| Sections | {summary['sections']} |",
        f"| Teachers | {summary['teachers']} |",
        f"| Assignments | {summary['assignments']} |",
        f"| Assessment score fact rows | {summary['assessment_score_facts']} |",
        f"| LMS enrollment fact rows | {summary['lms_enrollment_facts']} |",
        f"| Warehouse validation checks passing | {summary['validation_passes']} / {summary['validation_checks']} |",
        f"| LMS roster records reconciled | {summary['matched_rosters']} / {summary['lms_enrollment_facts']} |",
        "",
        "## SQL Extracts",
        "",
        "| Extract | Rows |",
        "| --- | ---: |",
    ]

    for path in extract_paths:
        rows = read_extract_rows(path)
        lines.append(f"| `{path.name}` | {len(rows)} |")

    lines.extend(
        [
            "",
            "## Analysis Questions Supported",
            "",
            "- Which courses and sections show the strongest Assignment 01 to Assignment 02 growth?",
            "- Where are non-participation zeros concentrated by grade, course track, and attendance category?",
            "- Do Canvas-derived enrollment records reconcile with canonical synthetic enrollments before reporting?",
            "- Which star-schema tables should feed future dashboard views in `assessment-intelligence`?",
            "",
            "## Recommended Dashboard Inputs",
            "",
            "- `course_section_performance.csv` for section-level score views",
            "- `assignment_growth_by_course.csv` for growth diagnostics",
            "- `nonparticipation_by_group.csv` for missingness and attendance checks",
            "- `lms_enrollment_reconciliation.csv` for data-quality status",
            "",
            "All records are synthetic and public-safe.",
            "",
        ]
    )
    if any(path.name == "student_readiness_extract.csv" for path in extract_paths):
        lines.insert(-3, "- `student_readiness_extract.csv` for student-level synthetic readiness records")
    else:
        lines.insert(-3, "- `student_readiness_extract.csv` is omitted only for older or explicitly skipped extract sets")
    report_path.write_text("\n".join(lines), encoding="utf-8")


def run_duckdb(args: argparse.Namespace, output_dir: Path, report_path: Path) -> None:
    try:
        import duckdb
    except ImportError as exc:
        raise SystemExit(
            "DuckDB is required for SQL extraction. Install it with: make analytics-install"
        ) from exc

    warehouse = args.warehouse.resolve()
    output_dir = args.output_dir.resolve()
    require_warehouse(warehouse)
    output_dir.mkdir(parents=True, exist_ok=True)

    connection = duckdb.connect(str(warehouse), read_only=True)
    extract_paths: list[Path] = []
    for sql_path in sorted(EXTRACT_SQL_DIR.glob("*.sql")):
        name = extract_name(sql_path)
        output_path = output_dir / f"{name}.csv"
        query = sql_path.read_text(encoding="utf-8").strip().rstrip(";")
        connection.execute(
            f"COPY ({query}) TO '{escaped_sql_path(output_path)}' (HEADER, DELIMITER ',')"
        )
        rows = scalar(connection, f"SELECT COUNT(*) FROM read_csv_auto('{escaped_sql_path(output_path)}', HEADER=TRUE)")
        print(f"Exported {output_path}: {rows} rows")
        extract_paths.append(output_path)

    write_report(
        report_path,
        f"`{display_path(warehouse)}`",
        output_dir,
        extract_paths,
        duckdb_summary(connection),
    )
    print(f"Wrote report: {report_path}")
    connection.close()


def run_supabase(args: argparse.Namespace, output_dir: Path, report_path: Path) -> None:
    if args.supabase_access_mode == "data-api":
        run_supabase_data_api(args, output_dir, report_path)
    else:
        run_supabase_management_sql(args, output_dir, report_path)


def env_first(names: tuple[str, ...], env: dict[str, str]) -> str:
    for name in names:
        value = os.environ.get(name) or env.get(name)
        if value:
            return value
    return ""


def sort_key(row: dict[str, Any], columns: tuple[str, ...]) -> tuple[str, ...]:
    return tuple(str(row.get(column, "")) for column in columns)


def run_supabase_data_api(args: argparse.Namespace, output_dir: Path, report_path: Path) -> None:
    env = load_env(args.env_file)
    supabase_url = env_first(
        ("SYNTHETIC_EDUCATION_SUPABASE_URL",),
        env,
    )
    publishable_key = env_first(
        ("SYNTHETIC_EDUCATION_SUPABASE_PUBLISHABLE_KEY",),
        env,
    )
    if not supabase_url or not publishable_key:
        raise SystemExit(
            "Supabase Data API extraction requires SYNTHETIC_EDUCATION_SUPABASE_URL "
            "and SYNTHETIC_EDUCATION_SUPABASE_PUBLISHABLE_KEY."
        )

    client = SupabaseDataApiClient(supabase_url, publishable_key)
    output_dir.mkdir(parents=True, exist_ok=True)
    extract_paths: list[Path] = []
    for spec in SUPABASE_VIEW_EXTRACTS:
        if args.skip_readiness and spec.extract_name == "student_readiness_extract":
            continue
        rows = sorted(
            client.fetch_view(spec.view_name),
            key=lambda row: sort_key(row, spec.order_columns),
        )
        output_path = output_dir / spec.csv_name
        write_rows(output_path, rows)
        print(f"Exported {display_path(output_path)}: {len(rows)} rows")
        extract_paths.append(output_path)

    write_report(
        report_path,
        "Supabase public Data API views from `synthetic-education-data`",
        output_dir,
        extract_paths,
        data_api_summary(client),
    )
    print(f"Wrote report: {display_path(report_path)}")


def run_supabase_management_sql(args: argparse.Namespace, output_dir: Path, report_path: Path) -> None:
    env = load_env(args.env_file)
    access_token = os.environ.get("SUPABASE_ACCESS_TOKEN") or env.get("SUPABASE_ACCESS_TOKEN")
    if not access_token:
        raise SystemExit("SUPABASE_ACCESS_TOKEN is required for Supabase extraction.")

    project_ref = args.supabase_project_ref or find_supabase_project_ref(access_token, args.supabase_project_name)
    client = SupabaseManagementSqlClient(access_token, project_ref)
    output_dir.mkdir(parents=True, exist_ok=True)

    sql_paths = sorted(POSTGRES_EXTRACT_SQL_DIR.glob("*.sql"))
    if args.skip_readiness:
        sql_paths = [path for path in sql_paths if "student_readiness_extract" not in path.name]

    extract_paths: list[Path] = []
    for sql_path in sql_paths:
        name = extract_name(sql_path)
        output_path = output_dir / f"{name}.csv"
        query = sql_path.read_text(encoding="utf-8").strip().rstrip(";")
        rows = client.query(query)
        write_rows(output_path, rows)
        print(f"Exported {display_path(output_path)}: {len(rows)} rows")
        extract_paths.append(output_path)

    write_report(
        report_path,
        f"Supabase project `{args.supabase_project_name}` via Management API read-only SQL fallback",
        output_dir,
        extract_paths,
        supabase_summary(client),
    )
    print(f"Wrote report: {display_path(report_path)}")


def main() -> None:
    args = parse_args()
    default_output_dir, default_report_path = source_defaults(args.source)
    output_dir = (args.output_dir or default_output_dir).resolve()
    report_path = (args.report_path or default_report_path).resolve()

    if args.source == "supabase":
        run_supabase(args, output_dir, report_path)
    else:
        run_duckdb(args, output_dir, report_path)


if __name__ == "__main__":
    main()
