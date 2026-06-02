# Privacy Model

The project has two zones.

## Private Zone

The private zone may contain real exports, private assessment artifacts, raw LMS
data, and calibration notebooks. These files must stay out of public repos.

Allowed work in the private zone:

- inspect real score distributions
- calculate aggregate calibration statistics
- profile missingness and completion patterns
- test whether synthetic data resembles the private distribution

## Public Zone

The public zone contains only generated synthetic records, documentation,
dashboards, reports, and validation artifacts.

Allowed public artifacts:

- fake students
- fake teachers
- fake sections
- synthetic score histories
- aggregate metrics
- methodology documentation
- validation reports

Blocked public artifacts:

- `.env`, tokens, API keys, OAuth files, or credential JSON
- real names, emails, IDs, rosters, submissions, grades, or comments
- private Canvas or LMS URLs
- private assessment exports
- raw notebooks that reveal private paths or source filenames

## Release Gate

Before publishing or linking a dataset:

1. Run `scripts/validate_synthetic_privacy.py`.
2. Inspect the validation report.
3. Confirm no generated file includes private paths, emails, URLs, tokens, or
   Canvas references.
4. Confirm fake labels are obvious and not real people.
5. Confirm the README explains that data is synthetic.

