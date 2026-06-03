# Orchestration Process

Goal:
Optimize candidate-agent prompt or instruction patches against a frozen
baseline for the same Spec Kit skill command and scenario prompt.

Principle:
Candidate guidance should remain agnostic. It may define how the candidate
agent should operate generally, but it must not encode scenario-specific product
requirements or contradict the loaded Spec Kit workflow, templates, artifacts,
or checklist semantics. Reusable compatibility patches should be stored under
`prompts/variants/` and appended into the candidate agent's run-local
instruction file by the runner.

The loaded Spec Kit skill is part of the benchmark objective. Evaluations and
patches should optimize for skill-compliant artifact quality, not for an
unstated preference such as minimal scenario-only specifications. If a candidate
follows a selected skill's required structure, examples, artifact semantics, or
validation pattern, treat that as valid unless the generated content conflicts
with the scenario, leaks implementation detail, is unreasonable for that skill,
or overclaims artifact quality.

Run sequence:
1. Select one scenario prompt and one Spec Kit skill command. The default
   current skill command is `/speckit-specify`, but the same framework applies
   to other Spec Kit skills when their prerequisite artifacts are present.
2. Create a fresh baseline run with `scripts/run-agent.sh --role baseline`.
3. Persist the baseline prompt trace under `runs/baseline/<run-id>/_benchmark/`.
4. Treat the generated Spec Kit directory and skill-required files as the
   baseline output.
5. Score the baseline once using `evaluation/scoring-rubric.md` and store the
   frozen assessment under
   `reports/baselines/<scenario-id>/<baseline-run-id>.assessment.md`.
6. Create a fresh candidate run with `scripts/run-agent.sh --role candidate`.
7. If the selected iteration has a candidate patch, the runner appends it to the
   correct run-local instruction file.
8. Persist the candidate prompt trace under
   `runs/candidate/<run-id>/_benchmark/`.
9. Treat the generated Spec Kit directory and skill-required files as the
   candidate output.
10. Use the `boost-agent-outcomes` skill to compare the candidate output against
    the frozen baseline assessment. Do not rescore the baseline during candidate
    iteration.
11. If the comparison finds actionable candidate improvements, create the next
    prepared patch under the selected agent's patch family directory.
12. Record the prepared next patch in the comparison report.
13. Append the score and decision to `reports/score-ledger.jsonl`.
14. Update `reports/latest-comparison.md`.
15. Replay the candidate run with the new patch.
16. Stop when the candidate comparison finds no further actionable prompt
    improvements or when the configured stop rule is reached.

Patch targets:
- If the selected iteration has a candidate patch, append it to the correct
  run-local instruction file:
  - Vibe patches from `prompts/variants/agents-patches/` append to `AGENTS.md`.
  - Claude Code patches from `prompts/variants/claude-patches/` append to
    `CLAUDE.md`.

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
- Record the selected skill command in baseline assessments, comparison
  reports, and score-ledger rows so multi-skill results are not conflated.

Example:
```sh
agent-benchmark/scripts/run-agent.sh --role candidate --agent vibe --id scenario-001-vibe-agent-candidate-v002 --patch agent-candidate-v002.md --prompt "Create a simple to-do list app..."
```
