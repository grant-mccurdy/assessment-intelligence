#!/usr/bin/env python3
"""Rebuild and verify the hash-bound dashboard publication from its manifest."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from build_sql_dashboard_json import (
    DEFAULT_EXTRACT_DIR,
    DEFAULT_MANIFEST_OUTPUT,
    build_dashboard,
    build_publication_manifest,
    sha256_bytes,
)
from validate_synthetic_privacy import validate


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--extract-dir", type=Path, default=DEFAULT_EXTRACT_DIR)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST_OUTPUT)
    return parser.parse_args()


def fail(message: str) -> None:
    raise SystemExit(f"publication verification failed: {message}")


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    if manifest.get("schemaVersion") != "assessment-dashboard-manifest-v1":
        fail("unsupported or missing manifest schemaVersion")

    dashboard_meta = manifest.get("dashboard", {})
    generated_date = dashboard_meta.get("generatedDate")
    generated_at = manifest.get("generatedAt")
    if not generated_date or not generated_at:
        fail("manifest must record dashboard.generatedDate and generatedAt")

    dashboard = build_dashboard(args.extract_dir, generated_date)
    dashboard_bytes = (json.dumps(dashboard, indent=2) + "\n").encode("utf-8")
    expected = build_publication_manifest(
        dashboard,
        dashboard_bytes,
        args.extract_dir,
        generated_at,
    )
    if expected != manifest:
        mismatches = [
            key
            for key in sorted(set(expected) | set(manifest))
            if expected.get(key) != manifest.get(key)
        ]
        fail(f"manifest does not match the committed inputs: {', '.join(mismatches)}")

    failures = [finding for finding in validate(dashboard, 10) if finding.severity == "fail"]
    if failures:
        fail("privacy/schema validation failed: " + "; ".join(item.detail for item in failures))

    print(
        "verified dashboard publication: "
        f"{dashboard_meta['recordCounts']['syntheticStudentRecords']} synthetic student records, "
        f"{dashboard_meta['bytes']} bytes, sha256 {sha256_bytes(dashboard_bytes)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
