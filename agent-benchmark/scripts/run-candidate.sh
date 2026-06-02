#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNS_DIR="${BENCHMARK_DIR}/runs/candidate"
VARIANTS_DIR="${BENCHMARK_DIR}/prompts/variants"
DEFAULT_CONFIG="${BENCHMARK_DIR}/agents/vibe-config.toml"
DEFAULT_VARIANT="system-candidate-v001.md"
RUN_PROMPT_FILENAME="system-prompt.md"

RUN_ID=""
SCENARIO_PROMPT=""
SKILL_COMMAND="/speckit-specify"
CONFIG_FILE="${DEFAULT_CONFIG}"
PROMPT_VARIANT="${DEFAULT_VARIANT}"
SETUP_ONLY=0
VIBE_OUTPUT="text"

usage() {
  cat <<'USAGE'
Usage:
  run-candidate.sh [--id RUN_ID] [--prompt SCENARIO_PROMPT] [--skill SKILL_COMMAND] [--variant FILE] [--config FILE] [--output text|json|streaming] [--setup-only]

Creates a candidate run directory, installs Spec Kit for Vibe without Git
integration, writes the Vibe runtime config, copies a prepared candidate
system-prompt variant, and optionally calls Vibe with the skill command
prepended to the scenario prompt.

Defaults:
  --config  agent-benchmark/agents/vibe-config.toml
  --variant agent-benchmark/prompts/variants/system-candidate-v001.md
  --skill   /speckit-specify
  --output  text

Examples:
  run-candidate.sh --id 02 --setup-only
  run-candidate.sh --id 02 --variant system-candidate-v002.md --setup-only
  run-candidate.sh --id habit-tracker-v001 --prompt "I need a simple habit tracker..."
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
    --config)
      CONFIG_FILE="${2:-}"
      shift 2
      ;;
    --variant)
      PROMPT_VARIANT="${2:-}"
      shift 2
      ;;
    --setup-only)
      SETUP_ONLY=1
      shift
      ;;
    --output)
      VIBE_OUTPUT="${2:-}"
      shift 2
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

if [[ ! -f "${CONFIG_FILE}" ]]; then
  printf 'Missing Vibe config file: %s\n' "${CONFIG_FILE}" >&2
  exit 1
fi

if [[ "${PROMPT_VARIANT}" == */* ]]; then
  printf 'Prompt variant must be a filename under %s, got: %s\n' "${VARIANTS_DIR}" "${PROMPT_VARIANT}" >&2
  exit 1
fi

SYSTEM_PROMPT_FILE="${VARIANTS_DIR}/${PROMPT_VARIANT}"

if [[ ! -f "${SYSTEM_PROMPT_FILE}" ]]; then
  printf 'Missing prepared Vibe prompt variant: %s\n' "${SYSTEM_PROMPT_FILE}" >&2
  exit 1
fi

case "${VIBE_OUTPUT}" in
  text|json|streaming)
    ;;
  *)
    printf 'Invalid Vibe output format: %s\n' "${VIBE_OUTPUT}" >&2
    exit 1
    ;;
esac

RUN_DIR="${RUNS_DIR}/${RUN_ID}"

if [[ -e "${RUN_DIR}" ]]; then
  printf 'Run directory already exists, refusing to overwrite: %s\n' "${RUN_DIR}" >&2
  exit 1
fi

mkdir -p "${RUN_DIR}"

(
  cd "${RUN_DIR}"
  specify init --integration vibe --script sh --here --force --no-git
)

mkdir -p "${RUN_DIR}/specs"

mkdir -p "${RUN_DIR}/.vibe/prompts"
cp "${CONFIG_FILE}" "${RUN_DIR}/.vibe/config.toml"
cp "${SYSTEM_PROMPT_FILE}" "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}"
printf '%s\n' "${PROMPT_VARIANT}" > "${RUN_DIR}/.vibe/prompt-variant.txt"

mkdir -p "${RUN_DIR}/.vibe/logs/session"
SOURCE_VIBE_HOME="${VIBE_HOME:-${HOME}/.vibe}"
if [[ -f "${SOURCE_VIBE_HOME}/.env" && ! -e "${RUN_DIR}/.vibe/.env" ]]; then
  ln -s "${SOURCE_VIBE_HOME}/.env" "${RUN_DIR}/.vibe/.env"
fi

if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s|^save_dir = .*|save_dir = \"${RUN_DIR}/.vibe/logs/session\"|" "${RUN_DIR}/.vibe/config.toml"
else
  sed -i "s|^save_dir = .*|save_dir = \"${RUN_DIR}/.vibe/logs/session\"|" "${RUN_DIR}/.vibe/config.toml"
fi

printf 'Prepared candidate run: %s\n' "${RUN_DIR}"
printf 'Vibe config: %s\n' "${RUN_DIR}/.vibe/config.toml"
printf 'Vibe system prompt: %s\n' "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}"
printf 'Source prompt variant: %s\n' "${SYSTEM_PROMPT_FILE}"
printf 'Vibe home: %s\n' "${RUN_DIR}/.vibe"
printf 'Vibe session logs: %s\n' "${RUN_DIR}/.vibe/logs/session"
if [[ -e "${RUN_DIR}/.vibe/.env" ]]; then
  printf 'Vibe env file: %s\n' "${RUN_DIR}/.vibe/.env"
fi

if [[ "${SETUP_ONLY}" -eq 1 ]]; then
  exit 0
fi

if [[ -z "${SCENARIO_PROMPT}" ]]; then
  printf 'No --prompt provided. Candidate run is prepared but Vibe was not called.\n' >&2
  exit 0
fi

if [[ -n "${SKILL_COMMAND}" ]]; then
  VIBE_PROMPT="${SKILL_COMMAND} ${SCENARIO_PROMPT}"
else
  VIBE_PROMPT="${SCENARIO_PROMPT}"
fi

(
  cd "${RUN_DIR}"
  VIBE_HOME="${RUN_DIR}/.vibe" vibe -p "${VIBE_PROMPT}" --trust --agent auto-approve --output "${VIBE_OUTPUT}"
)
