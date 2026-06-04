# Agent Benchmark Workflow

This repository contains a small optimization harness for comparing fixed
baseline runs against candidate prompt or instruction variants on the same
task. The goal is not to crown a model. The goal is to make prompt changes
measurable, repeatable, and tied to generated artifacts instead of anecdotes.

The workflow is built around Spec Kit skill scenarios. Each run receives the
same scenario prompt and skill command, produces the artifacts required by that
skill, and is scored with the same rubric.

## Directory Map

- `agent-benchmark/0-orchestration.md`: benchmark operating process.
- `agent-benchmark/1-recipes/agents/<agent-key>/`: agent configuration and run
  recipes.
- `agent-benchmark/1-recipes/skills/`: skill installation and setup recipes.
- `agent-benchmark/2-evaluation/`: rubric, comparison method, and thresholds.
- `agent-benchmark/3-scenarios/`: benchmark scenario prompts.
- `agent-benchmark/4-scripts/run-agent.sh`: run materialization script.
- `agent-benchmark/5-prompts/0-agents/patches/<agent-key>/`: candidate prompt
  patches.
- `agent-benchmark/6-runs/0-experiments/`: evaluator-created run manifests.
- `agent-benchmark/6-runs/1-baseline/<agent-key>/<run-id>/`: baseline run
  workspaces.
- `agent-benchmark/6-runs/2-candidate/<agent-key>/<run-id>/`: candidate run
  workspaces.
- `agent-benchmark/7-reports/0-baselines/<agent-key>/`: frozen baseline
  assessments.
- `agent-benchmark/7-reports/1-comparisons/<agent-key>/`: candidate comparison
  reports.

Canonical agent keys are lowercase: `vibe` and `claude-code`.

## Supported CLI Integrations

The current harness works with Claude Code and Vibe CLI. Either integration can
be used in the baseline or candidate role as long as the run produces the
expected Spec Kit artifacts and benchmark traces.

Agent setup materials are stored under
`agent-benchmark/1-recipes/agents/<agent-key>/`. These recipes are Markdown
materials for evaluators and runners; skill installation is documented
separately under `agent-benchmark/1-recipes/skills/`.

Evaluator agents may instantiate experiments by producing an explicit manifest
under `agent-benchmark/6-runs/0-experiments/` and passing it with
`--experiment`. The manifest can select the agent, role, model, system prompt,
patch, output format, and agent-supported config variables. CLI flags override
manifest values, and manifest values override recipe defaults.

## What The Workflow Measures

Each output is scored from 0 to 100 across skill-relative dimensions:

- workflow completion
- artifact quality
- scenario and acceptance coverage, when applicable
- scope, assumptions, and edge cases, when applicable
- measurable outcomes or validation criteria, when applicable
- validation discipline

The baseline is scored once and then frozen. Candidate runs are compared against
that frozen baseline and against previous candidate runs. This avoids silently
moving the target while optimizing.

The comparison step should be driven by a third evaluator agent, not by either
the baseline or candidate agent being judged. In this harness, that evaluator
uses the `boost-agent-outcomes` skill to identify baseline strengths, candidate
weaknesses, shared defects, prompt-fixable gaps, and stop/continue decisions.

## Current State

The active benchmark state is fully reset. Previous experiment traces and
results have been cleared.

There are no active baseline assessments, candidate comparisons, score-ledger
records, latest-comparison snapshots, or selected best candidate patches. The
next benchmark cycle should create fresh baseline runs before any candidate
comparison.

## Optimization Loop

1. Select a scenario from `agent-benchmark/3-scenarios/scenarios.md`.
2. Run and score the fixed baseline.
3. Run the candidate with no patch.
4. Have a third evaluator agent compare candidate artifacts against the frozen
   baseline using `boost-agent-outcomes`.
5. If there are actionable instruction-level improvements, create the next
   candidate patch under `agent-benchmark/5-prompts/0-agents/patches/<agent-key>/`.
6. Replay the candidate with that patch.
7. Continue while scores do not regress and material improvements remain.
8. Stop when a candidate regresses, reaches parity with only preference
   differences left, has no actionable next improvement, or a configured max
   iteration count is reached.

Candidate progress is evaluated with a log-progress metric:

```text
ln((100 - previous_score) / (100 - new_score))
```

This gives more credit to improvements near the top of the scale, where each
additional point is harder to earn.

## Artifact Policy

Reusable harness files should be committed:

- `agent-benchmark/0-orchestration.md`
- `agent-benchmark/1-recipes/`
- `agent-benchmark/2-evaluation/`
- `agent-benchmark/3-scenarios/`
- `agent-benchmark/4-scripts/`
- `agent-benchmark/5-prompts/`
- `agent-benchmark/6-runs/0-experiments/README.md`
- `agent-benchmark/7-reports/`

Generated run outputs should not be published. The repo `.gitignore` excludes
run workspaces, generated experiment manifests, generated candidate comparison
outputs, and generated prompt patches by default.
