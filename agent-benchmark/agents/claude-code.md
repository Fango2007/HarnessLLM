# Claude Code Baseline Invocation

Purpose:
Run Claude Code as the fixed baseline agent for the Spec Kit benchmark.

Runtime setup:
- Create a fresh run directory under `agent-benchmark/runs/baseline/<run-id>/`.
- From inside that run directory, install Spec Kit with:
  `specify init --integration claude --script sh --here --force --no-git`

Command pattern:
`claude -p "$SKILL_COMMAND $SCENARIO_PROMPT" --append-system-prompt "$AUTOMATION_PROMPT" --model "sonnet" --permission-mode bypassPermissions --output-format stream-json`

Automation prompt:
`Execute the entire requested Spec Kit workflow in this invocation. Create the feature spec and requirements checklist before final response. Do not initialize Git, create Git branches, or execute Git hooks.`

Default skill command:
`/speckit-specify`

Script:
Use `agent-benchmark/scripts/run-baseline.sh` to prepare the run directory and
optionally call Claude Code.

Examples:
```sh
agent-benchmark/scripts/run-baseline.sh --id 01 --setup-only
agent-benchmark/scripts/run-baseline.sh --id habit-tracker-baseline --prompt "I need a simple habit tracker where I can define habits, record daily completion, and see progress over time."
```

Required checks:
- generated specs must be stored under `runs/baseline/<run-id>/specs/`
- raw streamed Claude output should be captured by the calling process when used in automation
