# Comparison Method

This document defines how to compare frozen baseline outputs against candidate
agent outputs.

Previous experiment traces and results have been reset. There are no active
baseline assessments or candidate comparisons. New comparison work must start
from fresh baseline runs and freshly scored baseline assessments.

## Inputs

Each comparison uses:

- Scenario ID and prompt from `3-scenarios/scenarios.md`.
- Skill command used for the run.
- Baseline run directory under
  `6-runs/1-baseline/<agent-key>/<run-id>/`.
- Baseline prompt trace under
  `6-runs/1-baseline/<agent-key>/<run-id>/_benchmark/`.
- Frozen baseline assessment under
  `7-reports/0-baselines/<agent-key>/<scenario-id>/`.
- Candidate run directory under
  `6-runs/2-candidate/<agent-key>/<run-id>/`.
- Candidate prompt trace under
  `6-runs/2-candidate/<agent-key>/<run-id>/_benchmark/`.
- Candidate patch under `5-prompts/0-agents/patches/<agent-key>/`, if used.
- Agent recipe material under `1-recipes/agents/<agent-key>/`.
- Selected model, selected system prompt, experiment manifest path, config
  overrides, rendered config path, and patch source from `_benchmark/`, when
  present.
- Install/version checks under `_benchmark/install-checks/`.
- Score ledger at `7-reports/score-ledger.jsonl`.

## Procedure

1. Read `_benchmark/scenario-prompt.txt`, `_benchmark/skill-command.txt`, and
   `_benchmark/agent-prompt.txt` for both baseline and candidate.
2. Read `_benchmark/install-checks/` and record the agent CLI path/version plus
   the Spec Kit CLI path/version when available.
3. Identify the loaded Spec Kit skill for the run, such as `/speckit-specify`,
   `/speckit-plan`, `/speckit-tasks`, or `/speckit-analyze`, and treat its
   workflow, template requirements, prerequisite artifacts, and output pattern
   as part of the evaluation target.
4. Confirm the candidate run used the same scenario prompt and skill command as
   the frozen baseline assessment and baseline prompt trace.
5. Confirm the candidate run produced the expected Spec Kit artifacts.
6. Load the frozen baseline assessment. Do not rescore the baseline during a
   candidate comparison.
7. Read the candidate artifacts required by the selected skill. For
   `/speckit-specify`, this normally includes `spec.md` and
   `checklists/requirements.md`.
8. Compare candidate findings against the frozen baseline findings before
   scoring:
   - baseline-only,
   - candidate-only,
   - shared by both outputs,
   - unclear.
9. Penalize shared defects consistently. Do not use a defect as evidence that
   the candidate is worse when the baseline has the same defect.
10. Inspect local agent logs only when needed to explain workflow behavior,
    stalls, tool failures, or missing artifacts.
11. Score only the candidate using `scoring-rubric.md`; copy the baseline score,
    category breakdown, findings, and assessment ID from the frozen baseline
    assessment.
12. Use `boost-agent-outcomes` with this comparison frame: evaluate how well
    each output follows the selected Spec Kit skill for the same scenario and
    skill command, not a stricter or different artifact preference.
13. Apply `acceptance-thresholds.md` to decide whether to stop or continue.
14. Write the comparison report under
    `7-reports/1-comparisons/<agent-key>/`.
15. Append the score record to `7-reports/score-ledger.jsonl`.
16. Update `7-reports/latest-comparison.md`.

## Fairness Rule

The baseline is not assumed to be correct. It must be scored independently once
before candidate optimization starts, then persisted as a frozen baseline
assessment.

The skill is part of the task definition. Do not penalize an output merely for
following the loaded skill's required structure, examples, or success-criteria
pattern. Penalize only the parts that are poor under the scenario, the skill,
and the rubric together.

Candidate comparisons must not silently reinterpret, rescore, or overwrite the
baseline. If a baseline error is discovered later, create a new versioned
baseline assessment and mark which comparison reports are superseded. All later
candidate reports must cite the new baseline assessment ID.

When a baseline and candidate share a defect, the comparison report must either
penalize both outputs under the same rubric category or explicitly exclude the
defect from the relative candidate-vs-baseline criticism and record it as a
shared harness/process issue.

## Report Naming

Use this format:

```text
7-reports/1-comparisons/<agent-key>/<scenario-id>-<candidate-patch-or-run>.md
```

Example:

```text
7-reports/1-comparisons/vibe/scenario-001-agent-candidate-v001.md
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
- Candidate patch, if any.
- Loaded skill command.
- Skill scoring profile and any skill-compliance considerations that materially
  affect scoring.
- Candidate prompt trace paths.
- Baseline artifact paths.
- Candidate artifact paths.
- Agent local log path, if applicable.
- Install/version checks from `_benchmark/install-checks/`.
- Baseline score.
- Candidate score.
- Score delta from previous candidate, if any.
- Findings ordered by severity.
- `boost-agent-outcomes` summary.
- Recommended candidate patch changes, if any.
- Continue or stop decision.
- Stop reason, if stopping.

## Prompt Trace

Every run must persist the exact prompt inputs under `_benchmark/` before the
agent is invoked.

Common trace files include:

- `_benchmark/run-id.txt`
- `_benchmark/run-type.txt`
- `_benchmark/agent.txt`
- `_benchmark/model.txt`
- `_benchmark/skill-command.txt`
- `_benchmark/scenario-prompt.txt`
- `_benchmark/agent-prompt.txt`
- `_benchmark/output-format.txt`
- `_benchmark/install-checks/`

Candidate runs also include:

- `_benchmark/candidate-patch.txt`
- `_benchmark/candidate-patch-source.txt`, when a patch is used

Vibe runs also include:

- `_benchmark/system-prompt-source.txt`
- `_benchmark/run-system-prompt.txt`
- `_benchmark/config-source.txt`
- `_benchmark/run-config.txt`
- `_benchmark/rendered-config-path.txt`

Claude Code runs also include:

- `_benchmark/automation-system-prompt.txt`
- `_benchmark/run-instructions.txt`

Do not infer the experiment prompt from terminal history,
`7-reports/latest-comparison.md`, or memory. The `_benchmark/agent-prompt.txt`
file is the prompt that was sent to the agent.

## Score Ledger

`7-reports/score-ledger.jsonl` is the canonical score timeline. It centralizes
every persisted score and decision while delegating detailed reasoning to the
baseline assessment or comparison report referenced by each row.

After the full reset, there are no active ledger records. Create or append
ledger rows only from the fresh benchmark cycle.

Each new ledger row must include:

- `record_id`
- `record_type` (`baseline_assessment` or `candidate_comparison`)
- `recorded_at`
- `scenario_id`
- `skill_command`
- `agent`
- `run_id`
- `baseline_run_id`
- `baseline_assessment_id`
- `baseline_assessment_path`
- `patch_id`
- `score`
- `baseline_score`
- `previous_candidate_score`
- `delta_from_previous_candidate`
- `delta_from_baseline`
- `decision`
- `accepted`
- `scope`
- `source_report`
- `source_summary`
- `supersedes`
- `superseded_by`
- `notes`

## Baseline Assessment Persistence

Create exactly one active baseline assessment for each baseline run before
candidate comparisons begin.

Store it under:

```text
7-reports/0-baselines/<agent-key>/<scenario-id>/<assessment-file>.md
```

The assessment must include:

- assessment ID
- scenario ID
- scenario prompt
- skill command
- baseline run ID
- baseline artifact paths
- scoring rubric path and version/date
- baseline score
- category breakdown
- baseline-only findings
- known shared-defect risks
- evaluator notes
- creation date

Once a baseline assessment has been used by a candidate comparison, treat it as
immutable. If the rubric, fairness rule, or artifact interpretation changes,
create a new assessment file with a new assessment ID and record which earlier
assessment it supersedes.

## Candidate Patch Improvement Rule

Do not author reusable improvements directly in run-local files such as
`AGENTS.md` or `CLAUDE.md`.

All candidate patch changes must be stored as versioned patches under the
candidate agent's patch family directory:

```text
5-prompts/0-agents/patches/vibe/
5-prompts/0-agents/patches/claude-code/
```

For Vibe candidate runs, the selected system prompt is copied into the run-local
Vibe home as `.vibe/prompts/<prompt-id>.md`, and `.vibe/config.toml` is rendered
from `1-recipes/agents/vibe/config.toml.template` plus experiment overrides.
The selected patch is appended to run-local `AGENTS.md`.

For Claude Code candidate runs, the selected patch is appended to the run-local
`CLAUDE.md` created by Spec Kit.
