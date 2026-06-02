# Orchestration Process

Goal:
Optimize the Vibe system prompt against a Claude Code baseline for the same
Spec Kit `/speckit-specify` scenario prompts.

Run sequence:
1. Select one scenario prompt from `scenarios.md`.
2. Create a fresh baseline run under `runs/baseline/<run-id>/`.
3. Inside the baseline run, install Spec Kit without Git integration:
   `specify init --integration claude --script sh --here --force --no-git`
4. Call Claude Code with the selected `/speckit-specify` scenario prompt.
5. Treat the generated Spec Kit directory and files as the baseline output.
6. Create a fresh candidate run under `runs/candidate/<run-id>/`.
7. Inside the candidate run, install Spec Kit without Git integration:
   `specify init --integration vibe --script sh --here --force --no-git`
8. Copy `agents/vibe-config.toml` to the run-local `.vibe/config.toml`.
9. Copy the selected prepared prompt variant from `prompts/variants/` to
   `.vibe/prompts/system-prompt.md`.
10. Call Vibe:
    `VIBE_HOME="runs/candidate/<run-id>/.vibe" vibe -p "$PROMPT" --trust --agent auto-approve`
11. Treat the generated Spec Kit directory and files as the candidate output.
12. Use the `boost-agent-outcomes` skill to compare the baseline and candidate
    outputs.
13. If the comparison finds actionable candidate prompt improvements, create the
    next prepared prompt variant under `prompts/variants/`.
14. Replay the candidate run with the new variant.
15. Stop when the candidate comparison finds no further actionable prompt
    improvements or when the configured stop rule is reached.

Prompt variant policy:
- `prompts/system-prompt-vibe.md` is the original Vibe system prompt reference.
- Candidate prompts under evaluation live only in `prompts/variants/`.
- Prompt variants are named `system-candidate-vNNN.md`.
- Before a candidate run, the selected prompt variant is copied and renamed to
  `.vibe/prompts/system-prompt.md`.
- Use `scripts/create-candidate-variant.py` to create the next versioned variant.

Storage policy:
- Store comparison reports under `reports/comparisons/`.
- Update `reports/latest-comparison.md` after each comparison.
- Store all candidate prompt variants under `prompts/variants/`.
- Store the selected best prompt pointer in `prompts/best-candidate.md`.
- Keep Vibe logs local to each run under
  `runs/candidate/<run-id>/.vibe/logs/session/`.
- Do not store prompt improvements in run-local `AGENTS.md` files.

Example:
```sh
agent-benchmark/scripts/create-candidate-variant.py improved-system-prompt.md
```
