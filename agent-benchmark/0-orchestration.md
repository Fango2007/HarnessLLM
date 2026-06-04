# Orchestration Process

Goal:
Optimize candidate-agent prompt or instruction patches against a frozen
baseline for the same Spec Kit skill command and scenario prompt.

Current state:
Previous experiment traces and results have been reset. There are no active
baseline assessments, candidate comparisons, score-ledger records,
latest-comparison snapshots, or selected best candidate patches. New benchmark
work starts by creating fresh baseline runs.

Principle:
Candidate guidance should remain agnostic. It may define how the candidate
agent should operate generally, but it must not encode scenario-specific product
requirements or contradict the loaded Spec Kit workflow, templates, artifacts,
or checklist semantics. Reusable compatibility patches are stored under
`5-prompts/0-agents/patches/<agent-key>/` and appended into the candidate
agent's run-local instruction file by the runner.

Agent setup is recipe-driven. Agent configuration and run materials live under
`1-recipes/agents/<agent-key>/`. Skill setup materials live under
`1-recipes/skills/`. Evaluator agents may create a shell-readable experiment
manifest under `6-runs/0-experiments/` to select a model, system prompt, patch,
and config overrides for the runner to materialize into the run-local setup.

Run sequence:

1. Select one scenario prompt from `3-scenarios/scenarios.md` and one Spec Kit
   skill command.
2. Create a fresh baseline run with
   `4-scripts/run-agent.sh --role baseline --agent <agent-key>`.
3. Persist the baseline trace under
   `6-runs/1-baseline/<agent-key>/<run-id>/_benchmark/`.
4. Treat the generated Spec Kit directory and skill-required files as the
   baseline output.
5. Score the baseline once using `2-evaluation/scoring-rubric.md` and store
   the frozen assessment under
   `7-reports/0-baselines/<agent-key>/<scenario-id>/`.
6. Create a fresh candidate run with
   `4-scripts/run-agent.sh --role candidate --agent <agent-key>`.
7. If the selected iteration has a candidate patch, the runner appends it to
   the correct run-local instruction file.
8. Persist the candidate trace under
   `6-runs/2-candidate/<agent-key>/<run-id>/_benchmark/`.
9. Treat the generated Spec Kit directory and skill-required files as the
   candidate output.
10. Use the `boost-agent-outcomes` skill to compare the candidate output
    against the frozen baseline assessment. Do not rescore the baseline during
    candidate iteration.
11. If the comparison finds actionable candidate improvements, create the next
    prepared patch under `5-prompts/0-agents/patches/<agent-key>/`.
12. Record the prepared next patch in the comparison report.
13. Append the score and decision to `7-reports/score-ledger.jsonl`.
14. Update `7-reports/latest-comparison.md`.
15. Replay the candidate run with the new patch.
16. Stop when the candidate comparison finds no further actionable prompt
    improvements or when the configured stop rule is reached.

## Patch Targets

- `vibe` patches are read from `5-prompts/0-agents/patches/vibe/` and appended
  to run-local `AGENTS.md`.
- `claude-code` patches are read from
  `5-prompts/0-agents/patches/claude-code/` and appended to run-local
  `CLAUDE.md`.

Candidate patches are not stored in `1-recipes/agents/`; that directory contains
configuration and run materials only.

## Storage Policy

- Store frozen baseline assessments under `7-reports/0-baselines/`.
- Store comparison reports under `7-reports/1-comparisons/<agent-key>/`.
- Store prompt traces and rendered config snapshots under each run's
  `_benchmark/` directory.
- Store install/version checks under
  `6-runs/<role-directory>/<agent-key>/<run-id>/_benchmark/install-checks/`.
- Store the generated score timeline in `7-reports/score-ledger.jsonl`.
- Store generated latest comparison status in
  `7-reports/latest-comparison.md`.
- Store generated selected best patch pointers in
  `7-reports/1-comparisons/best-candidates.md` and
  `5-prompts/0-agents/patches/best-candidates.md`.
- Keep local agent logs inside the generated run directory. Vibe logs are under
  the run-local `.vibe/logs/session/` directory.

Do not author prompt improvements directly in run-local instruction files.
Store reusable patches under the agent key's patch directory, then let the
runner append the selected patch into the run-local instruction file.

Do not edit a baseline assessment after it has been cited by a comparison
report. If baseline scoring needs correction, create a new assessment with a
new assessment ID and explicitly supersede the old one.

## Experiment Manifests

Store evaluator-created manifests under `6-runs/0-experiments/` when a run
needs explicit model, system-prompt, patch, or config override selection.

Manifests are shell-readable and may define:

- `AGENT`
- `ROLE`
- `RUN_ID`
- `MODEL`
- `SYSTEM_PROMPT`
- `SKILL_COMMAND`
- `PATCH`
- `OUTPUT_FORMAT`
- `CONFIG_VARS=(KEY=VALUE ...)`

CLI flags override manifest values. Manifest values override recipe defaults.
The runner rejects config keys not supported by the selected agent setup.

Example:

```sh
agent-benchmark/4-scripts/run-agent.sh --role candidate --agent vibe --id scenario-001-vibe-candidate-v001 --prompt "Create a simple to-do list app..."
```
