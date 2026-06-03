#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNS_DIR="${BENCHMARK_DIR}/runs/candidate"
PROMPTS_DIR="${BENCHMARK_DIR}/prompts"
AGENTS_PATCHES_DIR="${PROMPTS_DIR}/variants/agents-patches"
DEFAULT_CONFIG="${BENCHMARK_DIR}/agents/vibe-config.toml"
BASE_SYSTEM_PROMPT="${PROMPTS_DIR}/system-prompt-vibe.md"
RUN_PROMPT_FILENAME="system-prompt.md"

RUN_ID=""
SCENARIO_PROMPT=""
SKILL_COMMAND="/speckit-specify"
CONFIG_FILE="${DEFAULT_CONFIG}"
AGENTS_PATCH=""
SETUP_ONLY=0
VIBE_OUTPUT="text"

usage() {
  cat <<'USAGE'
Usage:
  run-candidate.sh [--id RUN_ID] [--prompt SCENARIO_PROMPT] [--skill SKILL_COMMAND] [--agents-patch FILE] [--config FILE] [--output text|json|streaming] [--setup-only]

Creates a candidate run directory, installs Spec Kit for Vibe without Git
integration, writes the Vibe runtime config, copies the original Vibe system
prompt, optionally appends a prepared AGENTS.md patch, and optionally calls Vibe
with the skill command prepended to the scenario prompt.

Defaults:
  --config       agent-benchmark/agents/vibe-config.toml
  --agents-patch none
  --skill        /speckit-specify
  --output       text

Examples:
  run-candidate.sh --id 02 --setup-only
  run-candidate.sh --id 01 --agents-patch agent-candidate-v001.md --setup-only
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
    --agents-patch)
      AGENTS_PATCH="${2:-}"
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

validate_candidate_artifacts() {
  local feature_json feature_dir spec_file checklist_file

  feature_json="${RUN_DIR}/.specify/feature.json"
  if [[ ! -f "${feature_json}" ]]; then
    printf 'Candidate workflow failed: missing %s\n' "${feature_json}" >&2
    printf 'Expected the speckit-specify workflow to persist the active feature pointer.\n' >&2
    return 1
  fi

  feature_dir="$(sed -n 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${feature_json}" | head -n 1)"
  if [[ -z "${feature_dir}" ]]; then
    printf 'Candidate workflow failed: %s does not contain feature_directory\n' "${feature_json}" >&2
    return 1
  fi

  spec_file="${RUN_DIR}/${feature_dir}/spec.md"
  checklist_file="${RUN_DIR}/${feature_dir}/checklists/requirements.md"

  if [[ ! -f "${spec_file}" ]]; then
    printf 'Candidate workflow failed: missing expected spec artifact %s\n' "${spec_file}" >&2
    return 1
  fi

  if [[ ! -f "${checklist_file}" ]]; then
    printf 'Candidate workflow failed: missing expected checklist artifact %s\n' "${checklist_file}" >&2
    return 1
  fi
}

write_prompt_trace() {
  local trace_dir

  trace_dir="${RUN_DIR}/_benchmark"
  mkdir -p "${trace_dir}"

  printf '%s\n' "${RUN_ID}" > "${trace_dir}/run-id.txt"
  printf '%s\n' "candidate" > "${trace_dir}/run-type.txt"
  printf '%s\n' "vibe" > "${trace_dir}/agent.txt"
  printf '%s\n' "${SKILL_COMMAND}" > "${trace_dir}/skill-command.txt"
  printf '%s\n' "${SCENARIO_PROMPT}" > "${trace_dir}/scenario-prompt.txt"
  printf '%s\n' "${VIBE_PROMPT}" > "${trace_dir}/agent-prompt.txt"
  printf '%s\n' "${BASE_SYSTEM_PROMPT}" > "${trace_dir}/system-prompt-source.txt"
  printf '%s\n' "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}" > "${trace_dir}/run-system-prompt.txt"
  printf '%s\n' "${CONFIG_FILE}" > "${trace_dir}/config-source.txt"
  printf '%s\n' "${RUN_DIR}/.vibe/config.toml" > "${trace_dir}/run-config.txt"
  printf '%s\n' "${VIBE_OUTPUT}" > "${trace_dir}/output-format.txt"

  if [[ -n "${AGENTS_PATCH_FILE}" ]]; then
    printf '%s\n' "${AGENTS_PATCH}" > "${trace_dir}/agents-patch.txt"
    printf '%s\n' "${AGENTS_PATCH_FILE}" > "${trace_dir}/agents-patch-source.txt"
  else
    printf '%s\n' "none" > "${trace_dir}/agents-patch.txt"
  fi
}

if [[ -z "${RUN_ID}" ]]; then
  RUN_ID="$(next_run_id)"
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  printf 'Missing Vibe config file: %s\n' "${CONFIG_FILE}" >&2
  exit 1
fi

if [[ ! -f "${BASE_SYSTEM_PROMPT}" ]]; then
  printf 'Missing original Vibe system prompt: %s\n' "${BASE_SYSTEM_PROMPT}" >&2
  exit 1
fi

if [[ -n "${AGENTS_PATCH}" ]]; then
  if [[ "${AGENTS_PATCH}" == */* ]]; then
    printf 'AGENTS patch must be a filename under %s, got: %s\n' "${AGENTS_PATCHES_DIR}" "${AGENTS_PATCH}" >&2
    exit 1
  fi

  AGENTS_PATCH_FILE="${AGENTS_PATCHES_DIR}/${AGENTS_PATCH}"

  if [[ ! -f "${AGENTS_PATCH_FILE}" ]]; then
    printf 'Missing prepared AGENTS patch: %s\n' "${AGENTS_PATCH_FILE}" >&2
    exit 1
  fi
else
  AGENTS_PATCH_FILE=""
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

if [[ -n "${AGENTS_PATCH_FILE}" ]]; then
  {
    printf '\n<!-- BENCHMARK AGENTS PATCH START: %s -->\n' "${AGENTS_PATCH}"
    cat "${AGENTS_PATCH_FILE}"
    printf '\n<!-- BENCHMARK AGENTS PATCH END: %s -->\n' "${AGENTS_PATCH}"
  } >> "${RUN_DIR}/AGENTS.md"
fi

mkdir -p "${RUN_DIR}/specs"

mkdir -p "${RUN_DIR}/.vibe/prompts"
cp "${CONFIG_FILE}" "${RUN_DIR}/.vibe/config.toml"
cp "${BASE_SYSTEM_PROMPT}" "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}"
printf '%s\n' "${BASE_SYSTEM_PROMPT}" > "${RUN_DIR}/.vibe/system-prompt-source.txt"
if [[ -n "${AGENTS_PATCH_FILE}" ]]; then
  printf '%s\n' "${AGENTS_PATCH}" > "${RUN_DIR}/.vibe/agents-patch.txt"
fi

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
printf 'Source system prompt: %s\n' "${BASE_SYSTEM_PROMPT}"
if [[ -n "${AGENTS_PATCH_FILE}" ]]; then
  printf 'AGENTS patch: %s\n' "${AGENTS_PATCH_FILE}"
fi
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

write_prompt_trace

(
  cd "${RUN_DIR}"
  VIBE_HOME="${RUN_DIR}/.vibe" vibe -p "${VIBE_PROMPT}" --trust --agent auto-approve --output "${VIBE_OUTPUT}"
)

validate_candidate_artifacts
