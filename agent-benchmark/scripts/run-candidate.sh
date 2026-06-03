#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUNS_DIR="${BENCHMARK_DIR}/runs/candidate"
PROMPTS_DIR="${BENCHMARK_DIR}/prompts"
AGENTS_PATCHES_DIR="${PROMPTS_DIR}/variants/agents-patches"
CLAUDE_PATCHES_DIR="${PROMPTS_DIR}/variants/claude-patches"
DEFAULT_CONFIG="${BENCHMARK_DIR}/agents/vibe-config.toml"
BASE_SYSTEM_PROMPT="${PROMPTS_DIR}/system-prompt-vibe.md"
RUN_PROMPT_FILENAME="system-prompt.md"

RUN_ID=""
SCENARIO_PROMPT=""
SKILL_COMMAND="/speckit-specify"
AGENT="vibe"
CONFIG_FILE="${DEFAULT_CONFIG}"
CANDIDATE_PATCH=""
SETUP_ONLY=0
OUTPUT_FORMAT=""
MODEL="sonnet"

usage() {
  cat <<'USAGE'
Usage:
  run-candidate.sh [--id RUN_ID] [--agent vibe|claude-code] [--prompt SCENARIO_PROMPT] [--skill SKILL_COMMAND] [--candidate-patch FILE] [--agents-patch FILE] [--config FILE] [--model MODEL] [--output FORMAT] [--setup-only]

Creates a candidate run directory, installs Spec Kit without Git integration,
optionally appends a prepared candidate patch, and optionally calls the selected
candidate agent with the skill command prepended to the scenario prompt.

Defaults:
  --agent       vibe
  --config       agent-benchmark/agents/vibe-config.toml
  --candidate-patch none
  --skill        /speckit-specify
  --model        sonnet       (claude-code only)
  --output       text         (vibe)
  --output       stream-json  (claude-code)

Patch lookup:
  --agent vibe        prompts/variants/agents-patches/<FILE>, appended to AGENTS.md
  --agent claude-code prompts/variants/claude-patches/<FILE>, appended to CLAUDE.md

Compatibility:
  --agents-patch is kept as a Vibe alias for --candidate-patch.

Examples:
  run-candidate.sh --id 02 --setup-only
  run-candidate.sh --id 01 --agents-patch agent-candidate-v001.md --setup-only
  run-candidate.sh --id habit-tracker-v001 --prompt "I need a simple habit tracker..."
  run-candidate.sh --agent claude-code --id todo-claude-v001 --candidate-patch claude-candidate-v001.md --prompt "Create a simple to-do list app..."
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
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --config)
      CONFIG_FILE="${2:-}"
      shift 2
      ;;
    --candidate-patch)
      CANDIDATE_PATCH="${2:-}"
      shift 2
      ;;
    --agents-patch)
      CANDIDATE_PATCH="${2:-}"
      shift 2
      ;;
    --model)
      MODEL="${2:-}"
      shift 2
      ;;
    --setup-only)
      SETUP_ONLY=1
      shift
      ;;
    --output)
      OUTPUT_FORMAT="${2:-}"
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
  printf '%s\n' "${AGENT}" > "${trace_dir}/agent.txt"
  printf '%s\n' "${SKILL_COMMAND}" > "${trace_dir}/skill-command.txt"
  printf '%s\n' "${SCENARIO_PROMPT}" > "${trace_dir}/scenario-prompt.txt"
  printf '%s\n' "${AGENT_PROMPT}" > "${trace_dir}/agent-prompt.txt"
  printf '%s\n' "${OUTPUT_FORMAT}" > "${trace_dir}/output-format.txt"

  if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
    printf '%s\n' "${CANDIDATE_PATCH}" > "${trace_dir}/candidate-patch.txt"
    printf '%s\n' "${CANDIDATE_PATCH_FILE}" > "${trace_dir}/candidate-patch-source.txt"
  else
    printf '%s\n' "none" > "${trace_dir}/candidate-patch.txt"
  fi

  case "${AGENT}" in
    vibe)
      printf '%s\n' "${BASE_SYSTEM_PROMPT}" > "${trace_dir}/system-prompt-source.txt"
      printf '%s\n' "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}" > "${trace_dir}/run-system-prompt.txt"
      printf '%s\n' "${CONFIG_FILE}" > "${trace_dir}/config-source.txt"
      printf '%s\n' "${RUN_DIR}/.vibe/config.toml" > "${trace_dir}/run-config.txt"
      if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
        printf '%s\n' "${CANDIDATE_PATCH}" > "${trace_dir}/agents-patch.txt"
        printf '%s\n' "${CANDIDATE_PATCH_FILE}" > "${trace_dir}/agents-patch-source.txt"
      else
        printf '%s\n' "none" > "${trace_dir}/agents-patch.txt"
      fi
      ;;
    claude-code)
      printf '%s\n' "${MODEL}" > "${trace_dir}/model.txt"
      printf '%s\n' "${CLAUDE_AUTOMATION_PROMPT}" > "${trace_dir}/automation-system-prompt.txt"
      printf '%s\n' "${RUN_DIR}/CLAUDE.md" > "${trace_dir}/run-instructions.txt"
      if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
        printf '%s\n' "${CANDIDATE_PATCH}" > "${trace_dir}/claude-patch.txt"
        printf '%s\n' "${CANDIDATE_PATCH_FILE}" > "${trace_dir}/claude-patch-source.txt"
      else
        printf '%s\n' "none" > "${trace_dir}/claude-patch.txt"
      fi
      ;;
  esac
}

append_candidate_patch() {
  case "${AGENT}" in
    vibe)
      {
        printf '\n<!-- BENCHMARK AGENTS PATCH START: %s -->\n' "${CANDIDATE_PATCH}"
        sed -n '1,$p' "${CANDIDATE_PATCH_FILE}"
        printf '\n<!-- BENCHMARK AGENTS PATCH END: %s -->\n' "${CANDIDATE_PATCH}"
      } >> "${RUN_DIR}/AGENTS.md"
      ;;
    claude-code)
      {
        printf '\n<!-- BENCHMARK CLAUDE PATCH START: %s -->\n' "${CANDIDATE_PATCH}"
        sed -n '1,$p' "${CANDIDATE_PATCH_FILE}"
        printf '\n<!-- BENCHMARK CLAUDE PATCH END: %s -->\n' "${CANDIDATE_PATCH}"
      } >> "${RUN_DIR}/CLAUDE.md"
      ;;
  esac
}

prepare_vibe_runtime() {
  mkdir -p "${RUN_DIR}/specs"

  mkdir -p "${RUN_DIR}/.vibe/prompts"
  cp "${CONFIG_FILE}" "${RUN_DIR}/.vibe/config.toml"
  cp "${BASE_SYSTEM_PROMPT}" "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}"
  printf '%s\n' "${BASE_SYSTEM_PROMPT}" > "${RUN_DIR}/.vibe/system-prompt-source.txt"
  if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
    printf '%s\n' "${CANDIDATE_PATCH}" > "${RUN_DIR}/.vibe/agents-patch.txt"
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
}

if [[ -z "${RUN_ID}" ]]; then
  RUN_ID="$(next_run_id)"
fi

case "${AGENT}" in
  vibe)
    SPECIFY_INTEGRATION="vibe"
    PATCHES_DIR="${AGENTS_PATCHES_DIR}"
    if [[ -z "${OUTPUT_FORMAT}" ]]; then
      OUTPUT_FORMAT="text"
    fi

    if [[ ! -f "${CONFIG_FILE}" ]]; then
      printf 'Missing Vibe config file: %s\n' "${CONFIG_FILE}" >&2
      exit 1
    fi

    if [[ ! -f "${BASE_SYSTEM_PROMPT}" ]]; then
      printf 'Missing original Vibe system prompt: %s\n' "${BASE_SYSTEM_PROMPT}" >&2
      exit 1
    fi
    ;;
  claude-code)
    SPECIFY_INTEGRATION="claude"
    PATCHES_DIR="${CLAUDE_PATCHES_DIR}"
    if [[ -z "${OUTPUT_FORMAT}" ]]; then
      OUTPUT_FORMAT="stream-json"
    fi
    ;;
  *)
    printf 'Invalid candidate agent: %s\n' "${AGENT}" >&2
    printf 'Supported agents: vibe, claude-code\n' >&2
    exit 1
    ;;
esac

if [[ -n "${CANDIDATE_PATCH}" ]]; then
  if [[ "${CANDIDATE_PATCH}" == */* ]]; then
    printf 'Candidate patch must be a filename under %s, got: %s\n' "${PATCHES_DIR}" "${CANDIDATE_PATCH}" >&2
    exit 1
  fi

  CANDIDATE_PATCH_FILE="${PATCHES_DIR}/${CANDIDATE_PATCH}"

  if [[ ! -f "${CANDIDATE_PATCH_FILE}" ]]; then
    printf 'Missing prepared candidate patch: %s\n' "${CANDIDATE_PATCH_FILE}" >&2
    exit 1
  fi
else
  CANDIDATE_PATCH_FILE=""
fi

case "${AGENT}:${OUTPUT_FORMAT}" in
  vibe:text|vibe:json|vibe:streaming|claude-code:text|claude-code:json|claude-code:stream-json)
    ;;
  vibe:*)
    printf 'Invalid Vibe output format: %s\n' "${OUTPUT_FORMAT}" >&2
    printf 'Supported Vibe output formats: text, json, streaming\n' >&2
    exit 1
    ;;
  claude-code:*)
    printf 'Invalid Claude Code output format: %s\n' "${OUTPUT_FORMAT}" >&2
    printf 'Supported Claude Code output formats: text, json, stream-json\n' >&2
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
  specify init --integration "${SPECIFY_INTEGRATION}" --script sh --here --force --no-git
)

if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
  append_candidate_patch
fi

if [[ "${AGENT}" == "vibe" ]]; then
  prepare_vibe_runtime
fi

printf 'Prepared candidate run: %s\n' "${RUN_DIR}"
printf 'Candidate agent: %s\n' "${AGENT}"
case "${AGENT}" in
  vibe)
    printf 'Vibe config: %s\n' "${RUN_DIR}/.vibe/config.toml"
    printf 'Vibe system prompt: %s\n' "${RUN_DIR}/.vibe/prompts/${RUN_PROMPT_FILENAME}"
    printf 'Source system prompt: %s\n' "${BASE_SYSTEM_PROMPT}"
    if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
      printf 'AGENTS patch: %s\n' "${CANDIDATE_PATCH_FILE}"
    fi
    printf 'Vibe home: %s\n' "${RUN_DIR}/.vibe"
    printf 'Vibe session logs: %s\n' "${RUN_DIR}/.vibe/logs/session"
    if [[ -e "${RUN_DIR}/.vibe/.env" ]]; then
      printf 'Vibe env file: %s\n' "${RUN_DIR}/.vibe/.env"
    fi
    ;;
  claude-code)
    printf 'Claude model: %s\n' "${MODEL}"
    printf 'Claude instructions: %s\n' "${RUN_DIR}/CLAUDE.md"
    if [[ -n "${CANDIDATE_PATCH_FILE}" ]]; then
      printf 'Claude patch: %s\n' "${CANDIDATE_PATCH_FILE}"
    fi
    ;;
esac

if [[ "${SETUP_ONLY}" -eq 1 ]]; then
  exit 0
fi

if [[ -z "${SCENARIO_PROMPT}" ]]; then
  printf 'No --prompt provided. Candidate run is prepared but %s was not called.\n' "${AGENT}" >&2
  exit 0
fi

if [[ -n "${SKILL_COMMAND}" ]]; then
  AGENT_PROMPT="${SKILL_COMMAND} ${SCENARIO_PROMPT}"
else
  AGENT_PROMPT="${SCENARIO_PROMPT}"
fi

CLAUDE_AUTOMATION_PROMPT="Automation requirement: execute the entire requested Spec Kit workflow in this invocation. Create the feature spec and requirements checklist before final response. Do not initialize Git, create Git branches, or execute Git hooks."

write_prompt_trace

case "${AGENT}" in
  vibe)
    (
      cd "${RUN_DIR}"
      VIBE_HOME="${RUN_DIR}/.vibe" vibe -p "${AGENT_PROMPT}" --trust --agent auto-approve --output "${OUTPUT_FORMAT}"
    )
    ;;
  claude-code)
    (
      cd "${RUN_DIR}"
      claude -p "${AGENT_PROMPT}" --append-system-prompt "${CLAUDE_AUTOMATION_PROMPT}" --model "${MODEL}" --permission-mode bypassPermissions --output-format "${OUTPUT_FORMAT}"
    )
    ;;
esac

validate_candidate_artifacts
