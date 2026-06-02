# Comparison Method

This document defines how to compare Claude Code baseline outputs against Vibe
candidate outputs.

## Inputs

Each comparison uses:

- Scenario ID and prompt from `scenarios.md`.
- Baseline run directory under `runs/baseline/<run-id>/`.
- Candidate run directory under `runs/candidate/<run-id>/`.
- Candidate prompt variant under `prompts/variants/`.
- Local Vibe logs under `runs/candidate/<run-id>/.vibe/logs/session/`.

## Procedure

1. Confirm both runs used the same scenario prompt.
2. Confirm both runs produced the expected Spec Kit artifacts.
3. Read the baseline `spec.md` and `requirements.md`.
4. Read the candidate `spec.md` and `requirements.md`.
5. Inspect local Vibe logs only when needed to explain workflow behavior,
   stalls, tool failures, or missing artifacts.
6. Score baseline and candidate using `scoring-rubric.md`.
7. Use `boost-agent-outcomes` to identify:
   - stronger output patterns in the baseline,
   - candidate weaknesses,
   - prompt-fixable gaps,
   - non-prompt-fixable failures,
   - whether a new candidate prompt variant is justified.
8. Apply `acceptance-thresholds.md` to decide whether to stop or continue.
9. Write the comparison report under `reports/comparisons/`.
10. Update `reports/latest-comparison.md`.

## Report Naming

Use this format:

```text
reports/comparisons/<scenario-id>-<candidate-variant>.md
```

Example:

```text
reports/comparisons/habit-tracker-system-candidate-v001.md
```

## Required Report Sections

Each comparison report must include:

- Scenario ID.
- Scenario prompt.
- Baseline run ID.
- Candidate run ID.
- Candidate prompt variant.
- Baseline artifact paths.
- Candidate artifact paths.
- Vibe local log path.
- Baseline score.
- Candidate score.
- Score delta from previous candidate, if any.
- Findings ordered by severity.
- `boost-agent-outcomes` summary.
- Recommended prompt changes, if any.
- Continue or stop decision.
- Stop reason, if stopping.

## Prompt Improvement Rule

Do not hide prompt improvements in run-local files such as `AGENTS.md`.

All candidate prompt changes must be stored as versioned prompt variants under:

```text
prompts/variants/
```

Before a candidate run, the selected variant is copied into the run-local Vibe
home as `.vibe/prompts/system-prompt.md`.
