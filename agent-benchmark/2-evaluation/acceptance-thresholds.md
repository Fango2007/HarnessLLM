# Acceptance Thresholds

This document defines when a candidate patch is good enough to keep, when the
optimization loop should continue, and when the iteration process is over.

## Scoring Scale

Each comparison produces a score from 0 to 100 using the benchmark scoring
rubric.

- **Baseline score**: frozen score from the persisted Claude Code baseline
  assessment for the scenario.
- **Candidate score**: candidate-agent output for the same scenario and patch.
- **Raw delta**: candidate score minus the previous candidate score for the
  same scenario.
- **Relative delta**: raw delta divided by the previous candidate score for the
  same scenario.
- **Cumulative relative delta**: latest candidate score minus the initial
  candidate score for the same scenario, divided by the initial candidate
  score.
- **Remaining-gap reduction**: raw delta divided by the previous candidate's
  remaining gap to 100.
- **Log progress delta**:
  `ln((100 - previous_candidate_score) / (100 - candidate_score))`.
- **Cumulative log progress delta**:
  `ln((100 - initial_candidate_score) / (100 - latest_candidate_score))`.
- **Baseline assessment**: frozen baseline score and findings persisted under
  `7-reports/0-baselines/<agent-key>/<scenario-id>/`.

## Minimum Candidate Acceptance

A candidate patch is acceptable only if all of these are true:

- It completes the full required workflow for the scenario.
- It follows the loaded Spec Kit skill workflow and produces artifacts in the
  expected skill/template shape.
- It produces all expected artifacts.
- It has no unresolved critical defects in the generated output.
- Its score is at least 80 out of 100.
- It is not more than 5 points below the Claude Code baseline for the same
  scenario.

The Claude Code baseline must be scored once before candidate iteration starts.
Candidate comparisons must reuse the frozen baseline assessment and must not
rescore the baseline. If a defect appears in both outputs, it must not be counted
as a candidate-only defect.

If the baseline assessment is found to be wrong, do not edit it in place after
it has been used. Create a new versioned baseline assessment, record what it
supersedes, and use the new assessment for later comparisons.

If a candidate comparison discovers a baseline issue that was missing from the
frozen assessment, classify whether the omission is material before changing the
optimization loop. Non-material shared issues can be noted in the comparison.
Material baseline omissions require a new versioned baseline assessment before
future candidate decisions rely on that issue.

If the candidate fails to complete the workflow or misses required artifacts,
the run is not acceptable regardless of score.

## Improvement Threshold

An iteration counts as a noticeable improvement only when both are true:

- The candidate improves by at least `0.05` log-progress points over the
  previous candidate for the same scenario, or the latest accepted candidate
  improves by at least `0.10` cumulative log-progress points over the initial
  candidate for the same scenario.
- The improvement addresses at least one material issue identified by
  `boost-agent-outcomes`.
- The improvement is not merely a correction of an issue that was also present
  in the baseline unless the same penalty or harness-level note is applied to
  the baseline.

Changes that only alter wording, formatting, or style do not count as noticeable
improvements unless they also improve clarity, completeness, testability, or
artifact quality in a way reflected by the rubric.

Use log progress instead of fixed raw-score thresholds because candidates often
begin near the upper end of the 100-point scale. The log function estimates
progress against the shrinking remaining gap to 100, so the same raw score gain
counts more when the candidate is already strong. For example, a move from 84 to
86 closes 12.5% of the remaining gap and has a cumulative log-progress delta of
`0.1335`, so it should be recognized as a real gain when it addresses material
rubric issues.

## Category Improvement Retention

A patch can be worth keeping even when it is not the new best full candidate.
If a narrow patch improves its declared target category without breaking
workflow completion, retain it as a category-improvement patch when all of these
are true:

- The target category score improves relative to the previous accepted
  candidate or reaches baseline parity.
- The patch was narrow enough that the category improvement is diagnosable.
- Any regressions in other categories are recorded and classified.
- The patch does not introduce critical defects or missing required artifacts.

Retained category-improvement patches are reusable evidence and possible
ingredients for a later composition experiment. They are not automatically the
selected best candidate. The selected best full candidate still depends on total
score, acceptance constraints, workflow reliability, and simplicity.

When a category-improvement patch is retained but not selected, record both
facts explicitly:

- `retain_category_patch`: yes
- `selected_best_candidate`: no
- target category and category-score delta
- offsetting regressions or deferred findings

## Continue Criteria

Continue the optimization loop when all of these are true:

- The latest candidate run completed successfully.
- `boost-agent-outcomes` identifies at least one actionable candidate-patch-level
  improvement.
- The suggested improvement is likely to affect a material rubric category.
- The latest candidate score did not regress relative to the previous candidate
  for the same scenario.
- The configured maximum iteration count, if any, has not been reached.

Candidate-patch-level improvements include changes to the candidate run-local
instructions that could improve workflow compatibility, artifact quality,
validation discipline, or reporting without changing the candidate agent's base
prompt or global configuration.

Candidate-patch-level improvements must be compatible with the loaded Spec Kit
skill. Do not continue optimization based on a proposed patch that forbids a
skill-required or skill-encouraged pattern unless the framework first changes
the skill/template or scoring rubric.

After workflow completion is reliable, continue with a new patch only when the
patch has one primary target category or one tightly related issue cluster.
Avoid patches that attempt to fix every remaining finding at once. Broad patches
make regressions hard to diagnose and should be split into category-level
iterations unless the remaining findings are inseparable parts of one defect.

## Stop Criteria

Stop iterating when any of these conditions is met:

- `boost-agent-outcomes` finds no actionable candidate-patch-level improvement.
- The latest candidate score regresses relative to the previous candidate for
  the same scenario.
- The candidate meets or exceeds the Claude Code baseline and remaining
  differences are preference-only.
- The configured maximum iteration count is reached.

Small positive improvements and flat non-regressing scores do not stop the loop
by themselves. If there is still an actionable candidate-patch-level improvement,
continue iterating until a regression, baseline parity with preference-only
differences, no actionable improvement, or the configured maximum iteration
count.

Non-prompt-fixable defects include:

- CLI or runtime failures.
- Missing or inaccessible logs.
- Spec Kit skill defects.
- Scenario ambiguity that requires a better scenario prompt.
- Model capability limits that persist despite prompt changes.

## Best Candidate Selection

The best candidate is selected per candidate agent, patch family, and scenario.
Do not use one global best patch when multiple candidate agents are tested.

The best candidate for a given agent is the highest-scoring accepted patch that
also satisfies the stop criteria.

If two accepted patches have the same score, choose the one with:

1. Fewer critical or major findings.
2. Better workflow reliability.
3. Simpler prompt changes.
4. Earlier version number.

Record selected patches in `7-reports/1-comparisons/best-candidates.md`, with
one row per candidate agent and patch family. Create the file only after a new
candidate comparison selects a best candidate.

## Required Stop Record

When the loop stops, the final comparison report must include:

- Scenario ID.
- Baseline run ID.
- Baseline assessment ID.
- Candidate run ID.
- Candidate patch, if any.
- Baseline score.
- Candidate score.
- A `## Score` section with baseline and candidate scores shown together for
  every rubric category.
- Finding classifications for all material scored findings.
- Score delta from the previous candidate.
- Whether the score regressed.
- Relative score delta from the previous candidate.
- Cumulative relative score delta from the initial candidate.
- Remaining-gap reduction from the previous candidate.
- Log progress delta from the previous candidate.
- Cumulative log progress delta from the initial candidate.
- Score ledger record ID.
- `boost-agent-outcomes` summary.
- Shared-defect classification summary.
- Next-patch target category and deferred findings, if another patch is
  recommended.
- Stop reason.
- Whether the selected candidate is accepted.
