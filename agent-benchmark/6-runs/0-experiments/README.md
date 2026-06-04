# Experiment Manifests

Evaluator agents may translate a natural-language experiment request into a
shell-readable manifest, then pass it to
`agent-benchmark/4-scripts/run-agent.sh --experiment FILE`.

The runner consumes explicit fields only; it does not parse natural language.

Example:

```sh
AGENT="vibe"
ROLE="candidate"
RUN_ID="scenario-001-vibe-devstral"
MODEL="devstral-medium"
SYSTEM_PROMPT="system-prompt"
SKILL_COMMAND="/speckit-specify"
PATCH="agent-candidate-v001.md"
OUTPUT_FORMAT="text"
CONFIG_VARS=(
  "api_timeout=600.0"
  "bash_permission=ask"
)
```

Precedence is deterministic:

1. CLI flags.
2. Experiment manifest values.
3. Agent recipe defaults.

Run-specific `.env` manifests are ignored by default. Commit only durable
examples or documentation.
