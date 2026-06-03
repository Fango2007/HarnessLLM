# Comparison Method

This document defines how to compare Claude Code baseline outputs against Vibe
candidate outputs.

## Inputs

Each comparison uses:

- Scenario ID and prompt from `scenarios.md`.
- Baseline run directory under `runs/baseline/<run-id>/`.
- Baseline prompt trace under `runs/baseline/<run-id>/_benchmark/`.
- Frozen baseline assessment under
  `reports/baselines/<scenario-id>/<baseline-run-id>.assessment.md`.
- Candidate run directory under `runs/candidate/<run-id>/`.
- Candidate prompt trace under `runs/candidate/<run-id>/_benchmark/`.
- Candidate AGENTS patch under `prompts/variants/agents-patches/`, if used.
- Local Vibe logs under `runs/candidate/<run-id>/.vibe/logs/session/`.
- Score ledger at `reports/score-ledger.jsonl`.

## Procedure

1. Read `_benchmark/scenario-prompt.txt`, `_benchmark/skill-command.txt`, and
   `_benchmark/agent-prompt.txt` for both baseline and candidate.
2. Confirm the candidate run used the same scenario prompt as the frozen
   baseline assessment and baseline prompt trace.
3. Confirm the candidate run produced the expected Spec Kit artifacts.
4. Load the frozen baseline assessment. Do not rescore the baseline during a
   candidate comparison.
5. Read the candidate `spec.md` and `requirements.md`.
6. Compare candidate findings against the frozen baseline findings before
   scoring:
   - baseline-only,
   - candidate-only,
   - shared by both outputs,
   - unclear.
7. Penalize shared defects consistently. Do not use a defect as evidence that
   the candidate is worse when the baseline has the same defect.
8. Inspect local Vibe logs only when needed to explain workflow behavior,
   stalls, tool failures, or missing artifacts.
9. Score only the candidate using `scoring-rubric.md`; copy the baseline score,
   category breakdown, findings, and assessment ID from the frozen baseline
   assessment.
10. Use `boost-agent-outcomes` to identify:
   - stronger output patterns in the baseline,
   - candidate weaknesses,
   - shared defects that require harness-level validation,
   - AGENTS-patch-fixable gaps,
   - non-prompt-fixable failures,
   - whether a new candidate AGENTS patch is justified.
11. Apply `acceptance-thresholds.md` to decide whether to stop or continue.
12. Write the comparison report under `reports/comparisons/`.
13. Append the score record to `reports/score-ledger.jsonl`.
14. Update `reports/latest-comparison.md`.

## Fairness Rule

The baseline is not assumed to be correct. It must be scored independently once
before candidate optimization starts, then persisted as a frozen baseline
assessment.

Candidate comparisons must not silently reinterpret, rescore, or overwrite the
baseline. If a baseline error is discovered later, create a new versioned
baseline assessment and mark which comparison reports are superseded. All later
candidate reports must cite the new baseline assessment ID.

When a baseline and candidate share a defect, the comparison report must either:

- penalize both outputs under the same rubric category, or
- explicitly exclude the defect from the relative candidate-vs-baseline
  criticism and record it as a shared harness/process issue.

AGENTS patch recommendations must not be generated from shared defects unless
the recommendation is explicitly framed as improving both outputs or adding an
external validation gate to the harness.

## Report Naming

Use this format:

```text
reports/comparisons/<scenario-id>-<candidate-patch>.md
```

Example:

```text
reports/comparisons/habit-tracker-agent-candidate-v001.md
```

## Required Report Sections

Each comparison report must include:

- Scenario ID.
- Scenario prompt.
- Baseline run ID.
- Baseline assessment path.
- Baseline assessment ID.
- Baseline prompt trace paths.
- Candidate run ID.
- Candidate AGENTS patch, if any.
- Candidate prompt trace paths.
- Baseline artifact paths.
- Candidate artifact paths.
- Vibe local log path.
- Baseline score.
- Candidate score.
- Score delta from previous candidate, if any.
- Findings ordered by severity.
- `boost-agent-outcomes` summary.
- Recommended AGENTS patch changes, if any.
- Continue or stop decision.
- Stop reason, if stopping.

## Prompt Trace

Every run must persist the exact prompt inputs under `_benchmark/` before the
agent is invoked.

Baseline runs must include:

- `_benchmark/run-id.txt`,
- `_benchmark/run-type.txt`,
- `_benchmark/agent.txt`,
- `_benchmark/model.txt`,
- `_benchmark/skill-command.txt`,
- `_benchmark/scenario-prompt.txt`,
- `_benchmark/agent-prompt.txt`,
- `_benchmark/automation-system-prompt.txt`,
- `_benchmark/output-format.txt`.

Candidate runs must include:

- `_benchmark/run-id.txt`,
- `_benchmark/run-type.txt`,
- `_benchmark/agent.txt`,
- `_benchmark/skill-command.txt`,
- `_benchmark/scenario-prompt.txt`,
- `_benchmark/agent-prompt.txt`,
- `_benchmark/system-prompt-source.txt`,
- `_benchmark/run-system-prompt.txt`,
- `_benchmark/config-source.txt`,
- `_benchmark/run-config.txt`,
- `_benchmark/agents-patch.txt`,
- `_benchmark/agents-patch-source.txt`, when a patch is used,
- `_benchmark/output-format.txt`.

Do not infer the experiment prompt from terminal history, `latest-comparison.md`,
or memory. The `_benchmark/agent-prompt.txt` file is the prompt that was sent to
the agent.

## Score Ledger

`reports/score-ledger.jsonl` is the canonical score timeline. It centralizes
every persisted score and decision while delegating detailed reasoning to the
baseline assessment or comparison report referenced by each row.

Append one JSON object per scored baseline or candidate. Do not rewrite previous
rows to correct history. If a score is superseded, append a new row and set the
old row's `record_id` in the new row's `supersedes` list.

Each ledger row must include:

- `record_id`,
- `record_type` (`baseline_assessment` or `candidate_comparison`),
- `recorded_at`,
- `scenario_id`,
- `agent`,
- `run_id`,
- `baseline_run_id`,
- `baseline_assessment_id`,
- `baseline_assessment_path`,
- `patch_id`,
- `score`,
- `baseline_score`,
- `previous_candidate_score`,
- `delta_from_previous_candidate`,
- `delta_from_baseline`,
- `decision`,
- `accepted`,
- `scope`,
- `source_report`,
- `source_summary`,
- `supersedes`,
- `superseded_by`,
- `notes`.

## Baseline Assessment Persistence

Create exactly one active baseline assessment for each baseline run before
candidate comparisons begin.

Store it under:

```text
reports/baselines/<scenario-id>/<baseline-run-id>.assessment.md
```

The assessment must include:

- assessment ID,
- scenario ID,
- scenario prompt,
- baseline run ID,
- baseline artifact paths,
- scoring rubric path and version/date,
- baseline score,
- category breakdown,
- baseline-only findings,
- known shared-defect risks,
- evaluator notes,
- creation date.

Once a baseline assessment has been used by a candidate comparison, treat it as
immutable. Do not edit its score or findings in place. If the rubric, fairness
rule, or artifact interpretation changes, create a new assessment file with a
new assessment ID and record which earlier assessment it supersedes.

## AGENTS Patch Improvement Rule

Do not author improvements directly in run-local files such as `AGENTS.md`.

All candidate AGENTS patch changes must be stored as versioned patches under:

```text
prompts/variants/agents-patches/
```

Before a candidate run, the original Vibe system prompt is copied into the
run-local Vibe home as `.vibe/prompts/system-prompt.md`. The selected AGENTS
patch is appended to run-local `AGENTS.md`.
