# Vibe Candidate Invocation

Purpose:
Run Vibe as the candidate coding agent for the Spec Kit benchmark.

Runtime setup:
- Create a fresh run directory under `agent-benchmark/runs/candidate/<run-id>/`.
- From inside that run directory, install Spec Kit with:
  `specify init --integration vibe --script sh --here --force --no-git`
- Create `.vibe/prompts/`.
- Copy `agent-benchmark/agents/vibe-config.toml` to `.vibe/config.toml`.
- Select a prepared candidate prompt from `agent-benchmark/prompts/variants/`.
- Copy and rename that prompt variant to `.vibe/prompts/system-prompt.md`.
- Record the selected variant in `.vibe/prompt-variant.txt`.

Prompt variants:
- `agent-benchmark/prompts/system-prompt-vibe.md` is the original reference prompt.
- Candidate prompts that will be evaluated and optimized must be prepared under
  `agent-benchmark/prompts/variants/`.
- Run-local candidate prompts must always be named `.vibe/prompts/system-prompt.md`
  because `agents/vibe-config.toml` expects `system_prompt_id = "system-prompt"`.
- The initial candidate variant is
  `agent-benchmark/prompts/variants/system-candidate-v001.md`.
- New improved variants should be created with
  `agent-benchmark/scripts/create-candidate-variant.py`.

Command pattern:
`vibe -p "$SKILL_COMMAND $SCENARIO_PROMPT" --trust --agent auto-approve --output streaming`

Default skill command:
`/speckit-specify`

Script:
Use `agent-benchmark/scripts/run-candidate.sh` to prepare the run directory and
optionally call Vibe.

Examples:
```sh
agent-benchmark/scripts/run-candidate.sh --id 02 --setup-only
agent-benchmark/scripts/run-candidate.sh --id 02 --variant system-candidate-v002.md --setup-only
agent-benchmark/scripts/run-candidate.sh --id habit-tracker-v001 --prompt "I need a simple habit tracker where I can define habits, record daily completion, and see progress over time."
agent-benchmark/scripts/create-candidate-variant.py improved-system-prompt.md
```

Required checks:
- capture stdout/stderr
- capture generated Spec Kit files
- store outputs under `runs/candidate/`
