# Comparison Method

This document defines how to compare frozen baseline outputs against candidate
agent outputs.

## Inputs

Each comparison uses:

- Scenario ID and prompt from `scenarios.md`.
- Skill command used for the run.
- Baseline run directory under `runs/baseline/<run-id>/`.
- Baseline prompt trace under `runs/baseline/<run-id>/_benchmark/`.
- Frozen baseline assessment under
  `reports/baselines/<scenario-id>/<baseline-run-id>.assessment.md`.
- Candidate run directory under `runs/candidate/<run-id>/`.
- Candidate prompt trace under `runs/candidate/<run-id>/_benchmark/`.
- Candidate patch under the agent-specific patch directory, if used:
  - Vibe: `prompts/variants/agents-patches/`
  - Claude Code: `prompts/variants/claude-patches/`
- Local agent logs, when the candidate agent writes them. Vibe logs are under
  `runs/candidate/<run-id>/.vibe/logs/session/`.
- Score ledger at `reports/score-ledger.jsonl`.

## Procedure

1. Read `_benchmark/scenario-prompt.txt`, `_benchmark/skill-command.txt`, and
   `_benchmark/agent-prompt.txt` for both baseline and candidate.
2. Identify the loaded Spec Kit skill for the run, such as `/speckit-specify`,
   `/speckit-plan`, `/speckit-tasks`, or `/speckit-analyze`, and treat its
   workflow, template requirements, prerequisite artifacts, and output pattern
   as part of the evaluation target.
3. Define the skill scoring profile for this comparison:
   - required artifacts,
   - prerequisite artifacts,
   - category mapping for the generic rubric,
   - skill-compliant patterns that should not be penalized,
   - skill-specific quality failures that should be penalized.
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
10. Inspect local agent logs when needed to understand which skill instructions,
   templates, or agent-local guidance shaped the artifact. If a criticized
   pattern is explicitly encouraged by the loaded skill, classify it as
   skill-compliant unless it conflicts with the scenario or rubric.
11. Inspect local agent logs only when needed to explain workflow behavior,
   stalls, tool failures, or missing artifacts.
12. Score only the candidate using `scoring-rubric.md`; copy the baseline score,
   category breakdown, findings, and assessment ID from the frozen baseline
   assessment.
13. Use `boost-agent-outcomes` with the explicit comparison frame:
   "Evaluate how well each output follows the selected Spec Kit skill for the
   same scenario and skill command, not a stricter or different artifact
   preference." Identify:
   - stronger output patterns in the baseline,
   - candidate weaknesses,
   - skill-compliant patterns that should not be penalized,
   - shared defects that require harness-level validation,
   - candidate-patch-fixable gaps,
   - non-prompt-fixable failures,
   - whether a new candidate patch is justified.
14. Apply `acceptance-thresholds.md` to decide whether to stop or continue.
15. Write the comparison report under `reports/comparisons/`.
16. Append the score record to `reports/score-ledger.jsonl`.
17. Update `reports/latest-comparison.md`.

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

When a baseline and candidate share a defect, the comparison report must either:

- penalize both outputs under the same rubric category, or
- explicitly exclude the defect from the relative candidate-vs-baseline
  criticism and record it as a shared harness/process issue.

Candidate patch recommendations must not be generated from shared defects
unless the recommendation is explicitly framed as improving both outputs or
adding an external validation gate to the harness.

Candidate patch recommendations must also avoid contradicting the loaded Spec
Kit skill. A patch may clarify how to apply the skill in benchmark scenarios,
but it must not ban a pattern the skill explicitly asks for unless the framework
has first changed the skill, template, or rubric.

## Report Naming

Use this format:

```text
reports/comparisons/<scenario-id>-<candidate-patch>.md
```

Example:

```text
reports/comparisons/scenario-001-agent-candidate-v001.md
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

Candidate runs must include these common trace files:

- `_benchmark/run-id.txt`,
- `_benchmark/run-type.txt`,
- `_benchmark/agent.txt`,
- `_benchmark/skill-command.txt`,
- `_benchmark/scenario-prompt.txt`,
- `_benchmark/agent-prompt.txt`,
- `_benchmark/candidate-patch.txt`,
- `_benchmark/candidate-patch-source.txt`, when a patch is used,
- `_benchmark/output-format.txt`.

Vibe candidate runs also include:

- `_benchmark/system-prompt-source.txt`,
- `_benchmark/run-system-prompt.txt`,
- `_benchmark/config-source.txt`,
- `_benchmark/run-config.txt`,
- `_benchmark/agents-patch.txt`,
- `_benchmark/agents-patch-source.txt`, when a patch is used.

Claude Code candidate runs also include:

- `_benchmark/model.txt`,
- `_benchmark/automation-system-prompt.txt`,
- `_benchmark/run-instructions.txt`,
- `_benchmark/claude-patch.txt`,
- `_benchmark/claude-patch-source.txt`, when a patch is used.

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

Each new ledger row must include:

- `record_id`,
- `record_type` (`baseline_assessment` or `candidate_comparison`),
- `recorded_at`,
- `scenario_id`,
- `skill_command`,
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

Historical rows created before the multi-skill schema may omit `skill_command`.
Do not rewrite old rows only to add it; add a superseding row if the missing
skill command affects interpretation.

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
- skill command,
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

## Candidate Patch Improvement Rule

Do not author reusable improvements directly in run-local files such as
`AGENTS.md` or `CLAUDE.md`.

All candidate patch changes must be stored as versioned patches under the
candidate agent's patch family directory:

```text
prompts/variants/agents-patches/
prompts/variants/claude-patches/
```

For Vibe candidate runs, the original Vibe system prompt is copied into the
run-local Vibe home as `.vibe/prompts/system-prompt.md`. The selected AGENTS
patch is appended to run-local `AGENTS.md`.

For Claude Code candidate runs, the selected CLAUDE patch is appended to the
run-local `CLAUDE.md` created by Spec Kit.
