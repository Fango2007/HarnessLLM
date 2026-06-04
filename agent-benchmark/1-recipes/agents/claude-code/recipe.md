# Claude Code Agent Recipe

Purpose:
Configure and run Claude Code as a benchmark agent.

This recipe covers only Claude Code installation checks, CLI option selection,
and Claude Code invocation. Skill installation is intentionally out of scope and
should be handled by a separate skill recipe.

## CLI Documentation

- Claude Code CLI reference: https://docs.claude.com/en/docs/claude-code/cli-reference

## Required Materials

Claude Code currently has no dedicated configuration template or prompt material
in this agents directory. Do not add a stored system prompt unless a real
Claude-specific setup material is intentionally introduced.

Generated optimization patches are not agent configuration materials and should
not be documented as owned by this recipe.

## Installation Check

Before running a Claude Code benchmark, check that the CLI is available and
persist the path and version in benchmark metadata:

```sh
command -v claude
claude --version
```

Persist the command outputs with the run trace under
`_benchmark/install-checks/claude-path.txt` and
`_benchmark/install-checks/claude-version.txt`.

## Configuration

Select the Claude Code model and output format explicitly for each experiment.
Do not rely on terminal history or interactive defaults.

The evaluator or runner may choose these values before invocation:

- model
- output format
- permission mode
- automation prompt supplied by the runner

Claude Code does not use a TOML configuration template in this benchmark
material.

## Run Pattern

Run Claude Code in non-interactive print mode:

```sh
claude -p "$AGENT_PROMPT" --append-system-prompt "$AUTOMATION_PROMPT" --model "$MODEL" --permission-mode bypassPermissions --output-format "$OUTPUT_FORMAT"
```

The benchmark runner is responsible for constructing `AGENT_PROMPT` and for
supplying any automation prompt used for the run.

## Trace Requirements

Persist enough metadata to reproduce the Claude Code invocation:

- Claude CLI path and version
- selected model
- output format
- permission mode
- automation prompt text or source
- run-local instruction file path
