# Synthetic Data Validation Report

Input: `../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json`
Overall status: **PASS**

## Dataset Summary

- Periods: 8
- Sections: 12
- Aggregate records: 96
- Synthetic student-period records: 2138

## Findings

- Pass: 8
- Warn: 0
- Fail: 0

| Severity | Check | Detail |
| --- | --- | --- |
| PASS | required keys | All expected dashboard sections are present. |
| PASS | forbidden fields | No high-risk private-data field names were found. |
| PASS | forbidden values | No emails, URLs, tokens, private paths, or Canvas references were found. |
| PASS | synthetic student ids | All student IDs match the generated fake ID pattern. |
| PASS | synthetic teacher labels | All teacher labels use public-safe fake labels. |
| PASS | percentage bounds | Scores, proficiency, and completion values are within 0-100. |
| PASS | minimum group size | All sections and aggregate records meet k >= 10. |
| PASS | bootstrap disclosure | Bootstrap disclosure states that private data was used only for calibration. |

This report validates the public synthetic artifact only. It does not inspect or publish private source exports.
