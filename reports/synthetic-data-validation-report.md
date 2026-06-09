# Synthetic Data Validation Report

Input: `../grant-mccurdy.github.io/data/synthetic/assessment-dashboard.json`
Overall status: **PASS**

## Dataset Summary

- Periods: 14
- Sections: 174
- Aggregate records: 348
- Synthetic student-period records: 4018

## Findings

- Pass: 7
- Warn: 1
- Fail: 0

| Severity | Check | Detail |
| --- | --- | --- |
| PASS | required keys | All expected dashboard sections are present. |
| PASS | forbidden fields | No high-risk private-data field names were found. |
| PASS | forbidden values | No emails, URLs, tokens, private paths, or Canvas references were found. |
| PASS | synthetic student ids | All student IDs match the generated fake ID pattern. |
| PASS | synthetic teacher labels | All teacher labels use public-safe fake labels. |
| PASS | percentage bounds | Scores, proficiency, and completion values are within 0-100. |
| WARN | minimum group size | sections: Y00-SEC-018 (9), Y00-SEC-019 (8), Y00-SEC-020 (8), Y01-SEC-024 (4), Y02-SEC-022 (8), Y02-SEC-023 (8), Y02-SEC-024 (6), Y03-SEC-001 (8), Y03-SEC-002 (8), Y03-SEC-012 (9); records: Y00-SEC-018-assignment-01 (9), Y00-SEC-018-assignment-02 (9), Y00-SEC-019-assignment-01 (8), Y00-SEC-019-assignment-02 (8), Y00-SEC-020-assignment-01 (8), Y00-SEC-020-assignment-02 (8), Y01-SEC-024-assignment-03 (4), Y01-SEC-024-assignment-04 (4), Y02-SEC-022-assignment-05 (8), Y02-SEC-022-assignment-06 (8) |
| PASS | bootstrap disclosure | Disclosure states that private rows and identifiers are excluded. |

This report validates the public synthetic artifact only. It does not inspect or publish private source exports.
