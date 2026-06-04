# Vibe Agent Recipe

Purpose:
Configure and run Vibe as a benchmark agent.

This recipe covers only Vibe installation checks, Vibe configuration, prompt
material selection, and Vibe invocation. Skill installation is intentionally
out of scope and should be handled by a separate skill recipe.

## CLI Documentation

- Vibe install and setup: https://docs.mistral.ai/vibe/code/cli/install-setup
- Vibe configuration: https://docs.mistral.ai/vibe/code/cli/configuration

## Required Materials

- `config.toml.template`: template for the run-local `.vibe/config.toml`.
- `system-prompts/system-prompt.md`: default selectable Vibe system prompt.

Generated optimization patches are not agent configuration materials and should
not be documented as owned by this recipe.

## Installation Check

Before running a Vibe benchmark, check that the CLI is available and persist the
path and version in benchmark metadata:

```sh
command -v vibe
vibe --version
```

Persist the command outputs with the run trace under
`_benchmark/install-checks/vibe-path.txt` and
`_benchmark/install-checks/vibe-version.txt`.

## Configuration

Create a run-local Vibe home, then render `.vibe/config.toml` from
`config.toml.template`.

The evaluator or runner may choose these values before rendering:

- model alias
- provider settings
- system prompt id
- API timeout
- tool permissions
- session log directory

The selected system prompt id must match the prompt filename without the `.md`
extension.

## Run Pattern

Run Vibe with an explicit run-local home so the benchmark uses the rendered
configuration and prompt materials:

```sh
VIBE_HOME="$RUN_DIR/.vibe" vibe -p "$AGENT_PROMPT" --trust --agent auto-approve --output "$OUTPUT_FORMAT"
```

The benchmark runner is responsible for constructing `AGENT_PROMPT` from the
selected experiment inputs.

## Trace Requirements

Persist enough metadata to reproduce the Vibe configuration:

- Vibe CLI path and version
- selected model
- selected system prompt source
- rendered config path
- config template source
- config override values
- output format
