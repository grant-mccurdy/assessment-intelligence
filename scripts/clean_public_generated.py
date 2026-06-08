#!/usr/bin/env python3
"""Remove selected regenerated public report files without touching private data."""

from __future__ import annotations

from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]

GENERATED_REPORTS = (
    "reports/ai-extract-review-prompt.md",
    "reports/ai-extract-review.json",
    "reports/ai-extract-review.md",
    "reports/sql_warehouse_assessment_extract.md",
    "reports/sql_warehouse_assessment_report.md",
    "reports/supabase_assessment_extract.md",
    "reports/supabase_assessment_report.md",
)


def main() -> int:
    removed = 0
    for relative_path in GENERATED_REPORTS:
        path = PROJECT_ROOT / relative_path
        if not path.exists():
            continue
        path.unlink()
        removed += 1
        print(f"removed {relative_path}")

    print(f"removed {removed} public generated report file(s)")
    print("private data directories were intentionally left untouched")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
