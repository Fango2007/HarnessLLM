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
8. For every material candidate issue, compare against the frozen baseline
   assessment before scoring. If the assessment does not mention the issue and
   it could plausibly be shared, inspect the relevant baseline artifact section.
9. Classify each material finding using the finding-classification rules below.
10. Penalize shared defects consistently. Do not use a defect as evidence that
    the candidate is worse when the baseline has the same defect.
11. Inspect local agent logs only when needed to explain workflow behavior,
    stalls, tool failures, or missing artifacts.
12. Score only the candidate using `scoring-rubric.md`; copy the baseline score,
    category breakdown, findings, and assessment ID from the frozen baseline
    assessment.
13. Use `boost-agent-outcomes` with this comparison frame: evaluate how well
    each output follows the selected Spec Kit skill for the same scenario and
    skill command, not a stricter or different artifact preference.
14. Apply `acceptance-thresholds.md` to decide whether to stop or continue.
15. Write the comparison report under
    `7-reports/1-comparisons/<agent-key>/`.
16. Append the score record to `7-reports/score-ledger.jsonl`.
17. Update `7-reports/latest-comparison.md`.

## Finding Classification

Before assigning candidate scores, build a finding-classification table for all
material issues and strengths that affect scoring.

Each row must answer:

- **Finding**: the concrete issue or strength being evaluated.
- **Baseline evidence**: where the baseline assessment or artifact has the same
  pattern, a different pattern, or no comparable pattern.
- **Candidate evidence**: where the candidate artifact shows the pattern.
- **Classification**:
  - `baseline-only-strength`: baseline includes useful behavior that is optional
    or inferred rather than explicit in the scenario.
  - `baseline-only-defect`: baseline has a defect the candidate avoids.
  - `candidate-only-defect`: candidate has a defect not present in the baseline.
  - `shared-same-severity`: both outputs have materially equivalent defects.
  - `candidate-worse-than-baseline`: both outputs have the issue, but the
    candidate version is more specific, contradictory, harmful, or broader.
  - `candidate-better-than-baseline`: both outputs address the area, and the
    candidate is materially clearer or more complete.
  - `not-scenario-relevant`: the difference is a preference or extra behavior
    not required by the scenario, skill, or rubric.
- **Scoring effect**: category affected and whether the issue changes the
  candidate score.

Do not score directly from the candidate artifact in isolation. Classification
comes first; scoring follows from the classification.

Use these scoring rules:

- `candidate-only-defect` and `candidate-worse-than-baseline` can reduce the
  candidate score.
- `shared-same-severity` must not be used as candidate-only criticism. Either
  exclude it from relative criticism or record it as a shared issue.
- `baseline-only-strength` can explain why the baseline is stronger, but only
  penalize the candidate when the behavior is relevant under the scenario,
  loaded skill, and rubric.
- `not-scenario-relevant` should not affect score.

If the classification reveals that the frozen baseline assessment missed a
material issue, follow the baseline-correction rule below before using that
issue to drive future optimization.

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

Shared-defect classification must distinguish broad shared scope assumptions
from materially stronger candidate commitments. For example, if the baseline
already has a single-device/browser assumption, a candidate should not be
penalized merely for comparable browser/device phrasing. Penalize only when the
candidate adds more specific implementation commitments, such as a storage
mechanism, framework, API, database, sync model, capacity target, or an internal
contradiction that the baseline does not share.

## Baseline Correction Rule

Do not edit a frozen baseline assessment in place after it has been cited by a
candidate comparison.

If a later comparison discovers a baseline issue that the assessment missed:

- If the missed issue does not materially affect category scores or candidate
  decisions, record it in the candidate comparison as a newly discovered shared
  issue and leave the baseline assessment unchanged.
- If the missed issue affects baseline category scores, shared-defect
  classification, acceptance decisions, or future patch direction, create a new
  versioned baseline assessment with a new assessment ID. The new assessment
  must cite the same baseline run/artifacts, include corrected category scores
  and findings, and set `Supersedes` to the previous assessment ID.
- Future candidate comparisons must cite the newest active baseline assessment.
- Existing comparison reports remain historical records. Mark them superseded
  only when the correction changes their score, decision, or selected-patch
  outcome.

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
- A `## Score` section with category-level scoring details that show baseline
  score and candidate score side by side for every rubric category.
- A finding-classification table with baseline evidence, candidate evidence,
  classification, and scoring effect for all material scored findings.
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

Each new candidate patch must declare one primary optimization target:

- workflow completion
- primary artifact quality
- scenario and coverage quality
- scope, assumptions, risks, and edge cases
- validation criteria and readiness
- validation discipline

After workflow completion is reliable, a patch should address one target
category at a time. Do not bundle unrelated instructions across multiple
categories merely because they all appear in the latest comparison report.
Bundling is allowed only when the instructions are inseparable parts of one
defect or when a workflow blocker prevents category-level scoring.

Every comparison report that prepares a next patch must include:

- the target category,
- the specific classified finding the patch addresses,
- the expected scoring effect,
- why the patch is narrow enough to diagnose after one replay,
- and any findings intentionally deferred to later iterations.

If a patch improves its declared target category but does not improve total
score, do not discard the result as useless. Record whether the patch should be
retained as a category-improvement patch, whether it is selected as the best
full candidate, and which regressions blocked full promotion. Category-retained
patches can inform later composition experiments, but composition should be
tested explicitly rather than assumed.
