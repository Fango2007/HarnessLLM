# Orchestration Process

Goal:
Optimize candidate-agent prompt or instruction patches against a frozen
baseline for the same Spec Kit `/speckit-specify` scenario prompts.

Principle:
Candidate guidance should remain agnostic. It may define how the candidate
agent should operate generally, but it must not encode scenario-specific product
requirements or contradict the loaded Spec Kit workflow, templates, artifacts,
or checklist semantics. Reusable compatibility patches should be stored under
`prompts/variants/` and appended into the candidate agent's run-local
instruction file by the runner.

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
9. Inside the candidate run, install Spec Kit without Git integration using the
   selected candidate integration.
10. Let `scripts/run-candidate.sh` prepare agent-specific runtime files.
11. If the selected iteration has a candidate patch, append it to the correct
   run-local instruction file:
   - Vibe patches from `prompts/variants/agents-patches/` append to `AGENTS.md`.
   - Claude Code patches from `prompts/variants/claude-patches/` append to
     `CLAUDE.md`.
12. Persist the candidate prompt trace under
    `runs/candidate/<run-id>/_benchmark/`.
13. Call the selected candidate agent through `scripts/run-candidate.sh`.
14. Treat the generated Spec Kit directory and files as the candidate output.
15. Use the `boost-agent-outcomes` skill to compare the candidate output against
    the frozen baseline assessment. Do not rescore the baseline during candidate
    iteration.
16. If the comparison finds actionable candidate improvements, create the next
    prepared patch under the selected agent's patch family directory.
17. Record the prepared next patch in the comparison report.
18. Append the score and decision to `reports/score-ledger.jsonl`.
19. Update `reports/latest-comparison.md`.
20. Replay the candidate run with the new patch.
21. Stop when the candidate comparison finds no further actionable prompt
    improvements or when the configured stop rule is reached.

Prompt variant policy:
- Vibe AGENTS patches are stored under `prompts/variants/agents-patches/` and
  are named `agent-candidate-vNNN.md`.
- Claude Code CLAUDE patches are stored under `prompts/variants/claude-patches/`
  and are named `claude-candidate-vNNN.md`.
- Patch history for all candidate agents is summarized in
  `prompts/variants/metadata.md`.
- Before a candidate run, the runner appends the selected patch to the
  candidate agent's run-local instruction file.
- Prefer run-local append patches for compatibility with the Spec Kit workflow.
  Do not add product-specific heuristics to base prompts based on one
  scenario's output.

Storage policy:
- Store frozen baseline assessments under `reports/baselines/`.
- Store prompt traces under each run's `_benchmark/` directory.
- Store comparison reports under `reports/comparisons/`.
- Store the append-only score timeline in `reports/score-ledger.jsonl`.
- Update `reports/latest-comparison.md` after each comparison.
- Store candidate patches under the selected agent's patch family directory.
- Store candidate patch improvement summaries in
  `prompts/variants/metadata.md`.
- Store selected best patch pointers in `prompts/best-candidates.md`, with one
  row per candidate agent and patch family.
- Keep local agent logs inside the generated run directory. Vibe logs are under
  `runs/candidate/<run-id>/.vibe/logs/session/`.
- Do not author prompt improvements directly in run-local instruction files.
  Store reusable patches under `prompts/variants/`, then let the runner append
  the selected patch into the run-local instruction file.
- Do not edit a baseline assessment after it has been cited by a comparison
  report. If baseline scoring needs correction, create a new assessment with a
  new assessment ID and explicitly supersede the old one.

Example:
```sh
agent-benchmark/scripts/create-agents-patch.py improved-agents-patch.md
```
