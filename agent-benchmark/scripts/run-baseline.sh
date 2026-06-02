#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNS_DIR="${BENCHMARK_DIR}/runs/baseline"

RUN_ID=""
SCENARIO_PROMPT=""
SKILL_COMMAND="/speckit-specify"
SETUP_ONLY=0

usage() {
  cat <<'USAGE'
Usage:
  run-baseline.sh [--id RUN_ID] [--prompt SCENARIO_PROMPT] [--skill SKILL_COMMAND] [--setup-only]

Creates a baseline run directory, installs Spec Kit for Claude Code without Git
integration, and optionally calls Claude with the skill command prepended to the
scenario prompt.

Defaults:
  --skill  /speckit-specify
  --model  sonnet

Examples:
  run-baseline.sh --id 01 --setup-only
  run-baseline.sh --id habit-tracker-baseline --prompt "I need a simple habit tracker..."
USAGE
}

next_run_id() {
  local n id
  n=1
  while true; do
    printf -v id "%02d" "${n}"
    if [[ ! -e "${RUNS_DIR}/${id}" ]]; then
      printf '%s\n' "${id}"
      return 0
    fi
    n=$((n + 1))
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      RUN_ID="${2:-}"
      shift 2
      ;;
    --prompt)
      SCENARIO_PROMPT="${2:-}"
      shift 2
      ;;
    --skill)
      SKILL_COMMAND="${2:-}"
      shift 2
      ;;
    --setup-only)
      SETUP_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${RUN_ID}" ]]; then
  RUN_ID="$(next_run_id)"
fi

RUN_DIR="${RUNS_DIR}/${RUN_ID}"

if [[ -e "${RUN_DIR}" ]]; then
  printf 'Run directory already exists, refusing to overwrite: %s\n' "${RUN_DIR}" >&2
  exit 1
fi

mkdir -p "${RUN_DIR}"

(
  cd "${RUN_DIR}"
  specify init --integration claude --script sh --here --force --no-git
)

printf 'Prepared baseline run: %s\n' "${RUN_DIR}"

if [[ "${SETUP_ONLY}" -eq 1 ]]; then
  exit 0
fi

if [[ -z "${SCENARIO_PROMPT}" ]]; then
  printf 'No --prompt provided. Baseline run is prepared but Claude Code was not called.\n' >&2
  exit 0
fi

CLAUDE_PROMPT="${SKILL_COMMAND} ${SCENARIO_PROMPT}"
CLAUDE_AUTOMATION_PROMPT="Automation requirement: execute the entire requested Spec Kit workflow in this invocation. Create the feature spec and requirements checklist before final response. Do not initialize Git, create Git branches, or execute Git hooks."

(
  cd "${RUN_DIR}"
  claude -p "${CLAUDE_PROMPT}" --append-system-prompt "${CLAUDE_AUTOMATION_PROMPT}" --model "sonnet" --permission-mode bypassPermissions --output-format stream-json
)
