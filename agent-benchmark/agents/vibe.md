# Vibe Candidate Invocation

Purpose:
Run Vibe as the candidate coding agent for the Spec Kit benchmark.

Runtime setup:
- Create a fresh run directory under `agent-benchmark/runs/candidate/<run-id>/`.
- From inside that run directory, install Spec Kit with:
  `specify init --integration vibe --script sh --here --force --no-git`
- Create `.vibe/prompts/`.
- Copy `agent-benchmark/agents/vibe-config.toml` to `.vibe/config.toml`.
- Copy the original Vibe system prompt from
  `agent-benchmark/prompts/system-prompt-vibe.md` to
  `.vibe/prompts/system-prompt.md`.
- Optionally append a prepared AGENTS patch from
  `agent-benchmark/prompts/variants/agents-patches/` to the run-local
  `AGENTS.md`.
- Record the system prompt source in `.vibe/system-prompt-source.txt`.
- Record the selected AGENTS patch in `.vibe/agents-patch.txt` when one is used.

Prompt and patch policy:
- `agent-benchmark/prompts/system-prompt-vibe.md` is the original reference prompt.
- Run-local system prompts must always be named `.vibe/prompts/system-prompt.md`
  because `agents/vibe-config.toml` expects `system_prompt_id = "system-prompt"`.
- The system prompt stays unchanged during optimization.
- Candidate improvements are prepared as AGENTS patches under
  `agent-benchmark/prompts/variants/agents-patches/`.

Command pattern:
`vibe -p "$SKILL_COMMAND $SCENARIO_PROMPT" --trust --agent auto-approve --output streaming`

Default skill command:
`/speckit-specify`

Script:
Use `agent-benchmark/scripts/run-agent.sh --role candidate --agent vibe` to
prepare the run directory and optionally call Vibe.

Examples:
```sh
agent-benchmark/scripts/run-agent.sh --role candidate --agent vibe --id 02 --setup-only
agent-benchmark/scripts/run-agent.sh --role candidate --agent vibe --id 01 --patch agent-candidate-v001.md --setup-only
agent-benchmark/scripts/run-agent.sh --role candidate --agent vibe --id habit-tracker-v001 --prompt "I need a simple habit tracker where I can define habits, record daily completion, and see progress over time."
```

Required checks:
- capture stdout/stderr
- capture generated Spec Kit files
- store outputs under `runs/candidate/`
