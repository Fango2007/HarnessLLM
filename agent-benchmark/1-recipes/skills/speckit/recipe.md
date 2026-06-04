# Spec Kit Skill Installation Recipe

Purpose:
Install Spec Kit skills into a fresh benchmark run workspace.

This recipe covers only Spec Kit CLI checks and skill installation. Agent
configuration and invocation are handled by agent recipes.

## CLI Documentation

- Spec Kit installation: https://github.github.io/spec-kit/installation.html
- Spec Kit CLI reference: https://github.github.io/spec-kit/reference/overview.html
- Spec Kit core commands: https://github.github.io/spec-kit/reference/core.html

## Installation Check

Before installing Spec Kit materials, check that the CLI is available and
persist the path and version in benchmark metadata:

```sh
command -v specify
specify --version
```

Persist the command outputs with the run trace, for example under
`_benchmark/install-checks/specify-path.txt` and
`_benchmark/install-checks/specify-version.txt`.

## Integration Mapping

Use the integration key for the agent being configured:

- Vibe: `vibe`
- Claude Code: `claude`

## Install Pattern

Run from inside the fresh benchmark run directory:

```sh
specify init --integration "$SPECIFY_INTEGRATION" --script sh --here --force --no-git
```

The benchmark runner is responsible for selecting `SPECIFY_INTEGRATION` from
the chosen agent and for persisting the selected skill command with the run
trace.

## Trace Requirements

Persist enough metadata to reproduce the skill installation:

- Specify CLI path and version
- selected integration key
- script type
- run-local `.specify/` metadata paths
- selected skill command
