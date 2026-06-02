# Acceptance Thresholds

This document defines when a candidate prompt variant is good enough to keep,
when the optimization loop should continue, and when the iteration process is
over.

## Scoring Scale

Each comparison produces a score from 0 to 100 using the benchmark scoring
rubric.

- **Baseline score**: Claude Code output for the scenario.
- **Candidate score**: Vibe output for the same scenario and prompt variant.
- **Delta**: candidate score minus the previous candidate score for the same
  scenario.

## Minimum Candidate Acceptance

A candidate variant is acceptable only if all of these are true:

- It completes the full required workflow for the scenario.
- It produces all expected artifacts.
- It has no unresolved critical defects in the generated output.
- Its score is at least 80 out of 100.
- It is not more than 5 points below the Claude Code baseline for the same
  scenario.

If the candidate fails to complete the workflow or misses required artifacts,
the run is not acceptable regardless of score.

## Improvement Threshold

An iteration counts as a noticeable improvement only when both are true:

- The candidate score improves by at least 3 points over the previous candidate
  variant for the same scenario.
- The improvement addresses at least one material issue identified by
  `boost-agent-outcomes`.

Changes that only alter wording, formatting, or style do not count as noticeable
improvements unless they also improve clarity, completeness, testability, or
artifact quality in a way reflected by the rubric.

## Continue Criteria

Continue the optimization loop when all of these are true:

- The latest candidate run completed successfully.
- `boost-agent-outcomes` identifies at least one actionable prompt-level
  improvement.
- The suggested improvement is likely to affect a material rubric category.
- The candidate has not already met the stop criteria below.

Prompt-level improvements include changes to the candidate system prompt that
could improve reasoning, workflow completion, artifact quality, requirements
coverage, validation discipline, or reporting.

## Stop Criteria

Stop iterating when any of these conditions is met:

- `boost-agent-outcomes` finds no actionable prompt-level improvement.
- The candidate score improves by less than 3 points for two consecutive
  candidate variants on the same scenario.
- The candidate meets or exceeds the Claude Code baseline and remaining
  differences are preference-only.
- Remaining defects are not prompt-fixable.
- The configured maximum iteration count is reached.

Non-prompt-fixable defects include:

- CLI or runtime failures.
- Missing or inaccessible logs.
- Spec Kit skill defects.
- Scenario ambiguity that requires a better scenario prompt.
- Model capability limits that persist despite prompt changes.

## Best Candidate Selection

The best candidate is the highest-scoring accepted variant that also satisfies
the stop criteria.

If two accepted variants have the same score, choose the one with:

1. Fewer critical or major findings.
2. Better workflow reliability.
3. Simpler prompt changes.
4. Earlier version number.

Record the selected variant in `prompts/best-candidate.md`.

## Required Stop Record

When the loop stops, the final comparison report must include:

- Scenario ID.
- Baseline run ID.
- Candidate run ID.
- Candidate prompt variant.
- Baseline score.
- Candidate score.
- Score delta from the previous candidate.
- `boost-agent-outcomes` summary.
- Stop reason.
- Whether the selected candidate is accepted.
