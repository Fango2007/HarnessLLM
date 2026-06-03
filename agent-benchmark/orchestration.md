# Orchestration Process

Goal:
Optimize the Vibe system prompt against a Claude Code baseline for the same
Spec Kit `/speckit-specify` scenario prompts.

Principle:
The candidate system prompt should remain agnostic. It may define how Vibe
operates generally, but it must not encode scenario-specific product
requirements or contradict the loaded Spec Kit workflow, templates, artifacts, or
checklist semantics. Spec Kit workflow compatibility patches should be placed in
the run-local `AGENTS.md`, not directly inserted into the base system prompt.

Run sequence:
1. Select one scenario prompt from `scenarios.md`.
2. Create a fresh baseline run under `runs/baseline/<run-id>/`.
3. Inside the baseline run, install Spec Kit without Git integration:
   `specify init --integration claude --script sh --here --force --no-git`
4. Persist the baseline prompt trace under `runs/baseline/<run-id>/_benchmark/`.
5. Call Claude Code with the selected `/speckit-specify` scenario prompt.
6. Treat the generated Spec Kit directory and files as the baseline output.
7. Score the baseline once using `evaluation/scoring-rubric.md` and store the
   frozen assessment under
   `reports/baselines/<scenario-id>/<baseline-run-id>.assessment.md`.
8. Create a fresh candidate run under `runs/candidate/<run-id>/`.
9. Inside the candidate run, install Spec Kit without Git integration:
   `specify init --integration vibe --script sh --here --force --no-git`
10. Copy `agents/vibe-config.toml` to the run-local `.vibe/config.toml`.
11. Copy the original Vibe system prompt from `prompts/system-prompt-vibe.md` to
   `.vibe/prompts/system-prompt.md`.
12. If the selected iteration has an AGENTS patch under
    `prompts/variants/agents-patches/`, append it to the run-local `AGENTS.md`
    created by Spec Kit.
13. Persist the candidate prompt trace under
    `runs/candidate/<run-id>/_benchmark/`.
14. Call Vibe:
    `VIBE_HOME="runs/candidate/<run-id>/.vibe" vibe -p "$PROMPT" --trust --agent auto-approve`
15. Treat the generated Spec Kit directory and files as the candidate output.
16. Use the `boost-agent-outcomes` skill to compare the candidate output against
    the frozen baseline assessment. Do not rescore the baseline during candidate
    iteration.
17. If the comparison finds actionable candidate improvements, create the next
    prepared AGENTS patch under `prompts/variants/agents-patches/`.
18. Record the prepared next patch in the comparison report.
19. Append the score and decision to `reports/score-ledger.jsonl`.
20. Update `reports/latest-comparison.md`.
21. Replay the candidate run with the new patch.
22. Stop when the candidate comparison finds no further actionable prompt
    improvements or when the configured stop rule is reached.

Prompt variant policy:
- `prompts/system-prompt-vibe.md` is the original Vibe system prompt reference.
- The original Vibe system prompt stays fixed during optimization.
- AGENTS patches are stored under `prompts/variants/agents-patches/` and are
  named `agent-candidate-vNNN.md`.
- AGENTS patch history is summarized in `prompts/variants/metadata.md`.
- Before a candidate run, the original system prompt is copied and renamed to
  `.vibe/prompts/system-prompt.md`; the runner may append the selected patch to
  run-local `AGENTS.md`.
- Prefer AGENTS patches for compatibility with the Spec Kit workflow. Do not add
  product-specific heuristics to the system prompt based on one scenario's
  output.

Storage policy:
- Store frozen baseline assessments under `reports/baselines/`.
- Store prompt traces under each run's `_benchmark/` directory.
- Store comparison reports under `reports/comparisons/`.
- Store the append-only score timeline in `reports/score-ledger.jsonl`.
- Update `reports/latest-comparison.md` after each comparison.
- Store AGENTS patches under `prompts/variants/agents-patches/`.
- Store candidate patch improvement summaries in
  `prompts/variants/metadata.md`.
- Store the selected best prompt pointer in `prompts/best-candidate.md`.
- Keep Vibe logs local to each run under
  `runs/candidate/<run-id>/.vibe/logs/session/`.
- Do not author prompt improvements directly in run-local `AGENTS.md` files.
  Store reusable patches under `prompts/variants/agents-patches/`, then let the
  runner append the selected patch into the run-local `AGENTS.md`.
- Do not edit a baseline assessment after it has been cited by a comparison
  report. If baseline scoring needs correction, create a new assessment with a
  new assessment ID and explicitly supersede the old one.

Example:
```sh
agent-benchmark/scripts/create-agents-patch.py improved-agents-patch.md
```
