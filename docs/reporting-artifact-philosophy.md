# Reporting Artifact Philosophy

This project uses private graduate statistics coursework as an internal
reference for report discipline, not as public source material. The public repo
must not copy private report prose, assignment details, course identifiers,
datasets, figures, or case-specific examples.

The reusable philosophy is:

```text
recommendation first
-> data context and audit
-> model journey
-> final model or selected workflow
-> uncertainty, checks, and sensitivity
-> decision-ready bottom line
```

## Report Purpose

Assessment reports should help a school leader make a decision. They should not
read like a notebook dump or a generic dashboard caption. A strong report should
answer:

- What decision or question is this report supporting?
- What data is available, and what should not be overinterpreted?
- What model or summary method was chosen, and why?
- What are the strongest signals?
- What are the important caveats?
- What should happen next?

## Public-Safe Translation

Private statistical coursework can inform the reporting standard in these ways:

- put the recommendation or answer near the front
- separate audience-facing conclusions from technical model work
- show the model journey without making it the whole report
- include diagnostics, caveats, and sensitivity checks
- translate model output into decision language
- close with a practical bottom line

It cannot contribute:

- private report text
- private datasets
- private figures
- assignment prompts
- course names or identifiers
- professor, student, patient, or case names
- private file paths or filenames

## Standard Assessment Report Shape

Use this structure for public assessment artifacts:

1. **Recommendation**
   State the practical conclusion in restrained language.

2. **Direct Answers**
   Answer the specific reporting questions before giving technical detail.

3. **Data Context**
   Describe the synthetic source, population represented, time window, missing
   data behavior, and privacy boundary.

4. **Model Journey**
   Summarize candidate approaches and why the selected model/reporting method
   was chosen.

5. **Final Model or Reporting Method**
   Explain the selected model, metric, dashboard summary, or rule in plain
   language.

6. **Metric Scale**
   Translate scores, completion rates, growth values, and proficiency metrics
   into school-leader language.

7. **Model Checks**
   Include residuals, calibration, completion checks, distribution checks, or
   validation artifacts as appropriate.

8. **Sensitivity Checks**
   Show what changes if assumptions, completion thresholds, mastery benchmarks,
   or grouping choices change.

9. **Decision Scenarios**
   Provide a small number of synthetic scenarios that demonstrate how a leader
   would use the report.

10. **Bottom Line**
    Close with the highest-value finding, one caveat, and the next action.

## Writing Rules

- Prefer concrete claims tied to visible metrics.
- Avoid overclaiming from synthetic or incomplete data.
- Distinguish participation/completion from performance.
- Use charts and tables only when they help a decision.
- Explain uncertainty in professional language, not apologetic language.
- Keep technical details available, but do not force leaders to parse them
  before seeing the answer.

## Development Rule

When private coursework influences a public artifact, record the influence as a
general design principle. Do not copy private content. Do not publish private
source paths. Do not use private datasets as examples.
