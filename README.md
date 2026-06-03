# Agent Benchmark Workflow

This directory contains a small optimization harness for comparing a fixed
baseline run against candidate prompt or instruction variants on the same task.
The goal is not to crown a model. The goal is to make prompt changes measurable,
repeatable, and tied to generated artifacts instead of anecdotes.

The workflow is built around Spec Kit skill scenarios. Each run receives the
same scenario prompt and skill command, produces the artifacts required by that
skill, and is scored with the same rubric.

The task is to follow the selected Spec Kit skill, not to produce an arbitrary
evaluator-preferred artifact style. Skill-required or skill-encouraged patterns
should be penalized only when they conflict with the scenario, leak
implementation detail, are unreasonable for the selected skill, or make the
agent overclaim artifact quality.

Although the current setup uses small application specification prompts, the
same workflow can be adapted for other use cases where a stable baseline,
repeatable candidate runs, artifact scoring, and non-regression tracking are
useful.

## Supported CLI Integrations

The current harness works with Claude Code and Vibe CLI. Either integration can
be used in the baseline or candidate role as long as the run produces the
expected Spec Kit artifacts and prompt traces.

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
uses the [`boost-agent-outcomes`](https://github.com/Fango2007/AI-Skills) skill
to identify baseline strengths, candidate weaknesses, shared defects,
prompt-fixable gaps, and stop/continue decisions.

The evaluator must use the explicit comparison frame: assess how well each
output follows the selected Spec Kit skill for the same scenario and skill
command. Do not treat a skill-compliant pattern as a defect merely because a
different skill or stricter artifact style would avoid it.

## Optimization Loop

1. Select a scenario from `scenarios.md`.
2. Run and score the fixed baseline.
3. Run the candidate with no patch.
4. Have a third evaluator agent compare candidate artifacts against the frozen
   baseline using `boost-agent-outcomes`.
5. If there are actionable instruction-level improvements, create the next
   `agent-candidate-vNNN.md` patch.
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
additional point is harder to earn. For example, moving from 84 to 86 closes
12.5% of the remaining gap to 100.

## Current Example: Scenario 001

Scenario 001 asks for a simple to-do list app specification with add, complete,
edit, delete, and separate active/completed task sections.

The frozen baseline score is 89 / 100.

Candidate progression:

| Run | Patch | Score | Delta | Log Progress | Decision |
| --- | --- | ---: | ---: | ---: | --- |
| No patch | none | 84 | n/a | n/a | Continue |
| v001 | `agent-candidate-v001.md` | 85 | +1 | +0.0645 | Continue |
| v002 | `agent-candidate-v002.md` | 86 | +1 | +0.0690 | Continue |
| v003 | `agent-candidate-v003.md` | 82 | -4 | -0.2513 | Stop |

The best accepted candidate is `agent-candidate-v002.md`.

Why v002 was best:

- It improved lifecycle coverage over the no-patch run.
- It added stronger empty-state behavior.
- It preserved useful state and delete-safety guidance from earlier patches.
- It improved from 84 to 86, closing 12.5% of the remaining gap to 100.

Why the loop stopped:

- v003 regressed from 86 to 82.
- It increased implementation-detail leakage.
- It dropped delete-confirmation coverage.
- The non-regression rule stops the workflow on that regression.

## Artifact Policy

Reusable harness files should be committed:

- `agents/`
- `evaluation/`
- `prompts/`
- `scripts/`
- `scenarios.md`
- `orchestration.md`

Generated run outputs and result artifacts should not be published. The repo
`.gitignore` excludes run directories, generated reports, ledgers, latest-result
snapshots, generated candidate patches, and generated best-candidate pointers.

If a generated result needs to be shared, summarize it in a durable document
rather than committing the full run workspace.
