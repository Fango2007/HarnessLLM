#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RECIPES_DIR="${BENCHMARK_DIR}/1-recipes"
AGENT_RECIPES_DIR="${RECIPES_DIR}/agents"
PROMPT_PATCHES_DIR="${BENCHMARK_DIR}/5-prompts/0-agents/patches"
EXPERIMENTS_DIR="${BENCHMARK_DIR}/6-runs/0-experiments"
CALL_DIR="$(pwd)"

ROLE=""
AGENT=""
RUN_ID=""
SCENARIO_PROMPT=""
SKILL_COMMAND="/speckit-specify"
PATCH=""
SETUP_ONLY=0
NO_SKILL=0
OUTPUT_FORMAT=""
MODEL=""
SYSTEM_PROMPT=""
EXPERIMENT_FILE=""
CONFIG_TEMPLATE_FILE=""
AGENT_PROMPT=""
PATCH_FILE=""

CLI_ROLE=""
CLI_AGENT=""
CLI_RUN_ID=""
CLI_SCENARIO_PROMPT=""
CLI_SKILL_COMMAND=""
CLI_PATCH=""
CLI_NO_SKILL=0
CLI_OUTPUT_FORMAT=""
CLI_MODEL=""
CLI_SYSTEM_PROMPT=""
CLI_EXPERIMENT_FILE=""
CLI_CONFIG_TEMPLATE=""
CLI_CONFIG_VARS=()

CONFIG_VARS=()
MANIFEST_CONFIG_VARS=()
COMBINED_CONFIG_VARS=()
SUPPORTED_CONFIG_VARS=()
DEFAULT_CONFIG_VARS=()
SUPPORTED_OUTPUT_FORMATS=()

AGENT_NAME=""
SPECIFY_INTEGRATION=""
DEFAULT_OUTPUT_FORMAT=""
DEFAULT_MODEL=""
DEFAULT_SYSTEM_PROMPT=""
SYSTEM_PROMPT_DIR=""
CONFIG_TEMPLATE=""
PATCH_TARGET=""
PATCH_MARKER_LABEL=""
AGENT_CLI=""
AGENT_VERSION_CMD=()
SYSTEM_PROMPT_ID=""
SYSTEM_PROMPT_SOURCE=""
SYSTEM_PROMPT_TEXT=""
TRACE_DIR=""

SPEC_KIT_AUTOMATION_PROMPT="Automation requirement: execute the entire requested Spec Kit workflow in this invocation. Create the feature spec and requirements checklist before final response. Do not initialize Git, create Git branches, or execute Git hooks."
DIRECT_AUTOMATION_PROMPT="Automation requirement: complete the requested task in this invocation. Do not initialize Git, create Git branches, or execute Git hooks."
AUTOMATION_PROMPT="${SPEC_KIT_AUTOMATION_PROMPT}"

usage() {
  cat <<'USAGE'
Usage:
  run-agent.sh --role baseline|candidate --agent vibe|claude-code [--id RUN_ID] [--prompt SCENARIO_PROMPT] [--skill SKILL_COMMAND|--no-skill] [--patch FILE] [--model MODEL] [--system-prompt PROMPT_ID_OR_FILE] [--experiment FILE] [--config-var KEY=VALUE] [--config FILE] [--output FORMAT] [--setup-only]

Creates a benchmark run directory under:
  6-runs/1-baseline/<agent-key>/<run-id>/
  6-runs/2-candidate/<agent-key>/<run-id>/

Reads:
  agent recipes/materials from 1-recipes/agents/<agent-key>/
  Spec Kit installation recipe from 1-recipes/skills/speckit/
  candidate patches from 5-prompts/0-agents/patches/<agent-key>/
  experiment manifests from 6-runs/0-experiments/

Required unless provided by --experiment:
  --role   baseline or candidate
  --agent  vibe or claude-code

Experiment manifest fields:
  AGENT, ROLE, RUN_ID, SCENARIO_PROMPT, SKILL_COMMAND, PATCH, OUTPUT_FORMAT,
  MODEL, SYSTEM_PROMPT, CONFIG_TEMPLATE, CONFIG_VARS=(KEY=VALUE ...)

Use --no-skill or SKILL_COMMAND=none to run the agent directly without Spec Kit
setup, skill-prefixing, or Spec Kit artifact validation.

Precedence:
  CLI flags override experiment values. Experiment values override agent defaults.

Examples:
  run-agent.sh --role baseline --agent claude-code --id scenario-001-baseline --prompt "Create a simple to-do list app..."
  run-agent.sh --role candidate --agent vibe --id scenario-001-candidate-v001 --patch agent-candidate-v001.md --prompt "Create a simple to-do list app..."
  run-agent.sh --role candidate --agent vibe --model devstral-medium --system-prompt system-prompt --config-var api_timeout=600.0 --setup-only
  run-agent.sh --experiment scenario-001-vibe.env --setup-only
USAGE
}

require_arg() {
  local flag="${1}"
  local value="${2:-}"
  if [[ -z "${value}" ]]; then
    printf 'Missing value for %s\n' "${flag}" >&2
    exit 2
  fi
}

resolve_file() {
  local input="${1}"
  local resolved=""

  if [[ "${input}" = /* && -f "${input}" ]]; then
    resolved="${input}"
  elif [[ -f "${CALL_DIR}/${input}" ]]; then
    resolved="${CALL_DIR}/${input}"
  elif [[ -f "${BENCHMARK_DIR}/${input}" ]]; then
    resolved="${BENCHMARK_DIR}/${input}"
  elif [[ -f "${EXPERIMENTS_DIR}/${input}" ]]; then
    resolved="${EXPERIMENTS_DIR}/${input}"
  elif [[ -f "${input}" ]]; then
    resolved="$(cd "$(dirname "${input}")" && pwd)/$(basename "${input}")"
  fi

  [[ -n "${resolved}" ]] || return 1
  printf '%s\n' "${resolved}"
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

value_in_list() {
  local needle="${1}"
  shift
  local item
  for item in "$@"; do
    [[ "${item}" == "${needle}" ]] && return 0
  done
  return 1
}

configure_agent_defaults() {
  case "${AGENT}" in
    vibe)
      AGENT_NAME="Vibe"
      SPECIFY_INTEGRATION="vibe"
      DEFAULT_OUTPUT_FORMAT="text"
      DEFAULT_MODEL="devstral-medium"
      DEFAULT_SYSTEM_PROMPT="system-prompt"
      SYSTEM_PROMPT_DIR="${AGENT_RECIPES_DIR}/vibe/system-prompts"
      CONFIG_TEMPLATE="${AGENT_RECIPES_DIR}/vibe/config.toml.template"
      PATCH_TARGET="AGENTS.md"
      PATCH_MARKER_LABEL="AGENTS"
      AGENT_CLI="vibe"
      AGENT_VERSION_CMD=(vibe --version)
      SUPPORTED_OUTPUT_FORMATS=(text json streaming)
      SUPPORTED_CONFIG_VARS=(
        active_model api_timeout bash_default_timeout bash_max_output_bytes
        bash_permission disabled_tools enabled_tools grep_default_max_matches
        grep_default_timeout grep_max_output_bytes grep_permission mcp_servers
        model_alias model_input_price model_name model_output_price
        model_provider model_temperature model_thinking
        project_context_default_commit_count project_context_max_chars
        project_context_max_depth project_context_max_dirs_per_level
        project_context_max_doc_bytes project_context_max_files
        project_context_timeout_seconds project_context_truncation_buffer
        provider_api_base provider_api_key_env_var provider_api_style
        provider_backend provider_name read_file_max_read_bytes
        read_file_max_state_history read_file_permission
        search_replace_create_backup search_replace_fuzzy_threshold
        search_replace_max_content_size search_replace_permission
        session_logging_enabled session_prefix session_save_dir system_prompt_id
        todo_max_todos todo_permission tool_paths write_file_create_parent_dirs
        write_file_max_write_bytes write_file_permission
      )
      DEFAULT_CONFIG_VARS=(
        "active_model=devstral-medium"
        "api_timeout=720.0"
        "bash_default_timeout=30"
        "bash_max_output_bytes=16000"
        "bash_permission=ask"
        "disabled_tools=[]"
        "enabled_tools=[]"
        "grep_default_max_matches=100"
        "grep_default_timeout=60"
        "grep_max_output_bytes=64000"
        "grep_permission=always"
        "mcp_servers=[]"
        "model_alias=devstral-medium"
        "model_input_price=0.1"
        "model_name=devstral-medium-latest"
        "model_output_price=0.3"
        "model_provider=mistral"
        "model_temperature=0.2"
        "model_thinking=off"
        "project_context_default_commit_count=5"
        "project_context_max_chars=40000"
        "project_context_max_depth=3"
        "project_context_max_dirs_per_level=20"
        "project_context_max_doc_bytes=32768"
        "project_context_max_files=1000"
        "project_context_timeout_seconds=2.0"
        "project_context_truncation_buffer=1000"
        "provider_api_base=https://api.mistral.ai/v1"
        "provider_api_key_env_var=MISTRAL_API_KEY"
        "provider_api_style=openai"
        "provider_backend=mistral"
        "provider_name=mistral"
        "read_file_max_read_bytes=64000"
        "read_file_max_state_history=10"
        "read_file_permission=always"
        "search_replace_create_backup=false"
        "search_replace_fuzzy_threshold=0.9"
        "search_replace_max_content_size=100000"
        "search_replace_permission=ask"
        "session_logging_enabled=true"
        "session_prefix=session"
        "todo_max_todos=100"
        "todo_permission=always"
        "tool_paths=[]"
        "write_file_create_parent_dirs=true"
        "write_file_max_write_bytes=64000"
        "write_file_permission=ask"
      )
      ;;
    claude-code)
      AGENT_NAME="Claude Code"
      SPECIFY_INTEGRATION="claude"
      DEFAULT_OUTPUT_FORMAT="stream-json"
      DEFAULT_MODEL="sonnet"
      DEFAULT_SYSTEM_PROMPT=""
      SYSTEM_PROMPT_DIR=""
      CONFIG_TEMPLATE=""
      PATCH_TARGET="CLAUDE.md"
      PATCH_MARKER_LABEL="CLAUDE"
      AGENT_CLI="claude"
      AGENT_VERSION_CMD=(claude --version)
      SUPPORTED_OUTPUT_FORMATS=(text json stream-json)
      SUPPORTED_CONFIG_VARS=()
      DEFAULT_CONFIG_VARS=()
      ;;
    *)
      printf 'Invalid agent: %s\n' "${AGENT}" >&2
      printf 'Supported agents: vibe, claude-code\n' >&2
      exit 1
      ;;
  esac
}

config_key_supported() {
  local key="${1}"
  [[ "${#SUPPORTED_CONFIG_VARS[@]}" -gt 0 ]] || return 1
  value_in_list "${key}" "${SUPPORTED_CONFIG_VARS[@]}"
}

append_config_var_if_supported() {
  local pair="${1}"
  local key="${pair%%=*}"
  if config_key_supported "${key}"; then
    COMBINED_CONFIG_VARS+=("${pair}")
  fi
}

validate_config_vars() {
  local pair key
  [[ "${#COMBINED_CONFIG_VARS[@]}" -gt 0 ]] || return 0
  for pair in "${COMBINED_CONFIG_VARS[@]}"; do
    [[ "${pair}" == *=* ]] || {
      printf 'Invalid config-var, expected KEY=VALUE: %s\n' "${pair}" >&2
      exit 1
    }

    key="${pair%%=*}"
    [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
      printf 'Invalid config-var key: %s\n' "${key}" >&2
      exit 1
    }

    if ! config_key_supported "${key}"; then
      printf 'Unsupported config-var for %s: %s\n' "${AGENT}" "${key}" >&2
      if [[ "${#SUPPORTED_CONFIG_VARS[@]}" -gt 0 ]]; then
        printf 'Supported keys:\n' >&2
        printf '  %s\n' "${SUPPORTED_CONFIG_VARS[@]}" >&2
      else
        printf 'This agent does not support config-var overrides.\n' >&2
      fi
      exit 1
    fi
  done
}

config_value_for() {
  local key="${1}"
  local i pair pair_key
  for ((i=${#COMBINED_CONFIG_VARS[@]} - 1; i >= 0; i--)); do
    pair="${COMBINED_CONFIG_VARS[$i]}"
    pair_key="${pair%%=*}"
    if [[ "${pair_key}" == "${key}" ]]; then
      printf '%s\n' "${pair#*=}"
      return 0
    fi
  done
  return 1
}

rebuild_config_vars() {
  COMBINED_CONFIG_VARS=()
  if [[ "${#DEFAULT_CONFIG_VARS[@]}" -gt 0 ]]; then
    COMBINED_CONFIG_VARS+=("${DEFAULT_CONFIG_VARS[@]}")
  fi
  append_config_var_if_supported "session_save_dir=${RUN_DIR:-__RUN_DIR_NOT_ASSIGNED__}/.vibe/logs/session"
  append_config_var_if_supported "system_prompt_id=${SYSTEM_PROMPT_ID:-}"
  if config_key_supported "active_model" && [[ -n "${MODEL}" ]]; then
    COMBINED_CONFIG_VARS+=("active_model=${MODEL}" "model_alias=${MODEL}")
  fi
  if [[ "${#MANIFEST_CONFIG_VARS[@]}" -gt 0 ]]; then
    COMBINED_CONFIG_VARS+=("${MANIFEST_CONFIG_VARS[@]}")
  fi
  if [[ "${#CLI_CONFIG_VARS[@]}" -gt 0 ]]; then
    COMBINED_CONFIG_VARS+=("${CLI_CONFIG_VARS[@]}")
  fi
  validate_config_vars
}

render_config_template() {
  local template="${1}"
  local destination="${2}"
  local content key value placeholder

  [[ -f "${template}" ]] || {
    printf 'Missing config template for %s: %s\n' "${AGENT}" "${template}" >&2
    exit 1
  }

  content="$(sed -n '1,$p' "${template}")"
  if [[ "${#SUPPORTED_CONFIG_VARS[@]}" -gt 0 ]]; then
    for key in "${SUPPORTED_CONFIG_VARS[@]}"; do
      if config_value_for "${key}" >/dev/null; then
        value="$(config_value_for "${key}")"
        placeholder="{{${key}}}"
        content="${content//${placeholder}/${value}}"
      fi
    done
  fi

  if printf '%s\n' "${content}" | grep -q '{{[A-Za-z_][A-Za-z0-9_]*}}'; then
    printf 'Config template has unresolved placeholders: %s\n' "${template}" >&2
    printf '%s\n' "${content}" | grep '{{[A-Za-z_][A-Za-z0-9_]*}}' >&2
    exit 1
  fi

  printf '%s\n' "${content}" > "${destination}"
}

load_experiment_manifest() {
  [[ -n "${CLI_EXPERIMENT_FILE}" ]] || return 0

  if ! EXPERIMENT_FILE="$(resolve_file "${CLI_EXPERIMENT_FILE}")"; then
    printf 'Missing experiment manifest: %s\n' "${CLI_EXPERIMENT_FILE}" >&2
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  . "${EXPERIMENT_FILE}"
  set +a

  MANIFEST_CONFIG_VARS=("${CONFIG_VARS[@]}")
}

resolve_system_prompt() {
  local selected="${SYSTEM_PROMPT}"
  local candidate=""
  local basename_no_ext

  if [[ "${AGENT}" == "claude-code" ]]; then
    if [[ -n "${selected}" ]]; then
      printf 'Claude Code does not have selectable system-prompt materials in 1-recipes/agents/claude-code.\n' >&2
      exit 1
    fi
    SYSTEM_PROMPT_ID="none"
    SYSTEM_PROMPT_SOURCE="none"
    SYSTEM_PROMPT_TEXT=""
    return 0
  fi

  [[ -n "${selected}" ]] || selected="${DEFAULT_SYSTEM_PROMPT}"

  if candidate="$(resolve_file "${selected}")"; then
    SYSTEM_PROMPT_SOURCE="${candidate}"
  elif [[ -f "${SYSTEM_PROMPT_DIR}/${selected}" ]]; then
    SYSTEM_PROMPT_SOURCE="${SYSTEM_PROMPT_DIR}/${selected}"
  elif [[ -f "${SYSTEM_PROMPT_DIR}/${selected}.md" ]]; then
    SYSTEM_PROMPT_SOURCE="${SYSTEM_PROMPT_DIR}/${selected}.md"
  else
    printf 'Missing system prompt for %s: %s\n' "${AGENT}" "${selected}" >&2
    exit 1
  fi

  basename_no_ext="$(basename "${SYSTEM_PROMPT_SOURCE}")"
  SYSTEM_PROMPT_ID="${basename_no_ext%.md}"
  SYSTEM_PROMPT_TEXT="$(sed -n '1,$p' "${SYSTEM_PROMPT_SOURCE}")"
}

require_cli() {
  local cli="${1}"
  local path_var="${2}"
  local version_var="${3}"
  local path version

  if ! path="$(command -v "${cli}")"; then
    printf 'Missing required CLI: %s\n' "${cli}" >&2
    exit 1
  fi

  case "${cli}" in
    specify)
      version="$(specify --version 2>&1)"
      ;;
    vibe)
      version="$(vibe --version 2>&1)"
      ;;
    claude)
      version="$(claude --version 2>&1)"
      ;;
    *)
      version="unknown"
      ;;
  esac

  printf -v "${path_var}" '%s' "${path}"
  printf -v "${version_var}" '%s' "${version}"
}

write_install_checks() {
  local dir="${TRACE_DIR}/install-checks"
  mkdir -p "${dir}"
  printf '%s\n' "${SPECIFY_PATH}" > "${dir}/specify-path.txt"
  printf '%s\n' "${SPECIFY_VERSION}" > "${dir}/specify-version.txt"
  printf '%s\n' "${AGENT_CLI_PATH}" > "${dir}/${AGENT}-path.txt"
  printf '%s\n' "${AGENT_CLI_VERSION}" > "${dir}/${AGENT}-version.txt"
}

prepare_vibe_runtime() {
  mkdir -p "${RUN_DIR}/specs"
  mkdir -p "${RUN_DIR}/.vibe/prompts"
  mkdir -p "${RUN_DIR}/.vibe/logs/session"

  cp "${SYSTEM_PROMPT_SOURCE}" "${RUN_DIR}/.vibe/prompts/${SYSTEM_PROMPT_ID}.md"
  printf '%s\n' "${SYSTEM_PROMPT_SOURCE}" > "${RUN_DIR}/.vibe/system-prompt-source.txt"

  render_config_template "${CONFIG_TEMPLATE_FILE}" "${RUN_DIR}/.vibe/config.toml"

  if [[ -n "${PATCH_FILE}" ]]; then
    printf '%s\n' "${PATCH}" > "${RUN_DIR}/.vibe/agents-patch.txt"
  fi

  SOURCE_VIBE_HOME="${VIBE_HOME:-${HOME}/.vibe}"
  if [[ -f "${SOURCE_VIBE_HOME}/.env" && ! -e "${RUN_DIR}/.vibe/.env" ]]; then
    ln -s "${SOURCE_VIBE_HOME}/.env" "${RUN_DIR}/.vibe/.env"
  fi
}

prepare_agent_runtime() {
  case "${AGENT}" in
    vibe)
      prepare_vibe_runtime
      ;;
    claude-code)
      :
      ;;
  esac
}

append_patch() {
  {
    printf '\n<!-- BENCHMARK %s PATCH START: %s -->\n' "${PATCH_MARKER_LABEL}" "${PATCH}"
    sed -n '1,$p' "${PATCH_FILE}"
    printf '\n<!-- BENCHMARK %s PATCH END: %s -->\n' "${PATCH_MARKER_LABEL}" "${PATCH}"
  } >> "${RUN_DIR}/${PATCH_TARGET}"
}

write_config_trace() {
  if [[ "${#MANIFEST_CONFIG_VARS[@]}" -gt 0 ]]; then
    printf '%s\n' "${MANIFEST_CONFIG_VARS[@]}" > "${TRACE_DIR}/config-vars-manifest.txt"
  else
    printf '%s\n' "none" > "${TRACE_DIR}/config-vars-manifest.txt"
  fi

  if [[ "${#CLI_CONFIG_VARS[@]}" -gt 0 ]]; then
    printf '%s\n' "${CLI_CONFIG_VARS[@]}" > "${TRACE_DIR}/config-vars-cli.txt"
  else
    printf '%s\n' "none" > "${TRACE_DIR}/config-vars-cli.txt"
  fi

  : > "${TRACE_DIR}/config-vars-final.txt"
  local key value
  if [[ "${#SUPPORTED_CONFIG_VARS[@]}" -gt 0 ]]; then
    for key in "${SUPPORTED_CONFIG_VARS[@]}"; do
      if config_value_for "${key}" >/dev/null; then
        value="$(config_value_for "${key}")"
        printf '%s=%s\n' "${key}" "${value}" >> "${TRACE_DIR}/config-vars-final.txt"
      fi
    done
  fi
}

write_prompt_trace() {
  TRACE_DIR="${RUN_DIR}/_benchmark"
  mkdir -p "${TRACE_DIR}"

  printf '%s\n' "${RUN_ID}" > "${TRACE_DIR}/run-id.txt"
  printf '%s\n' "${ROLE}" > "${TRACE_DIR}/run-type.txt"
  printf '%s\n' "${AGENT}" > "${TRACE_DIR}/agent.txt"
  printf '%s\n' "${AGENT_NAME}" > "${TRACE_DIR}/agent-name.txt"
  printf '%s\n' "${SKILL_COMMAND}" > "${TRACE_DIR}/skill-command.txt"
  if [[ -z "${SKILL_COMMAND}" ]]; then
    printf '%s\n' "direct" > "${TRACE_DIR}/skill-mode.txt"
  else
    printf '%s\n' "speckit" > "${TRACE_DIR}/skill-mode.txt"
  fi
  printf '%s\n' "${SCENARIO_PROMPT}" > "${TRACE_DIR}/scenario-prompt.txt"
  printf '%s\n' "${AGENT_PROMPT}" > "${TRACE_DIR}/agent-prompt.txt"
  printf '%s\n' "${OUTPUT_FORMAT}" > "${TRACE_DIR}/output-format.txt"
  printf '%s\n' "${MODEL}" > "${TRACE_DIR}/model.txt"
  printf '%s\n' "${SPECIFY_INTEGRATION}" > "${TRACE_DIR}/specify-integration.txt"
  printf '%s\n' "${SYSTEM_PROMPT_ID}" > "${TRACE_DIR}/system-prompt-id.txt"
  printf '%s\n' "${SYSTEM_PROMPT_SOURCE}" > "${TRACE_DIR}/system-prompt-source.txt"

  if [[ -n "${EXPERIMENT_FILE}" ]]; then
    printf '%s\n' "${EXPERIMENT_FILE}" > "${TRACE_DIR}/experiment.txt"
  else
    printf '%s\n' "none" > "${TRACE_DIR}/experiment.txt"
  fi

  if [[ -n "${PATCH_FILE}" ]]; then
    printf '%s\n' "${PATCH}" > "${TRACE_DIR}/patch.txt"
    printf '%s\n' "${PATCH_FILE}" > "${TRACE_DIR}/patch-source.txt"
    if [[ "${ROLE}" == "candidate" ]]; then
      printf '%s\n' "${PATCH}" > "${TRACE_DIR}/candidate-patch.txt"
      printf '%s\n' "${PATCH_FILE}" > "${TRACE_DIR}/candidate-patch-source.txt"
    else
      printf '%s\n' "${PATCH}" > "${TRACE_DIR}/baseline-patch.txt"
      printf '%s\n' "${PATCH_FILE}" > "${TRACE_DIR}/baseline-patch-source.txt"
    fi
  else
    printf '%s\n' "none" > "${TRACE_DIR}/patch.txt"
    if [[ "${ROLE}" == "candidate" ]]; then
      printf '%s\n' "none" > "${TRACE_DIR}/candidate-patch.txt"
    else
      printf '%s\n' "none" > "${TRACE_DIR}/baseline-patch.txt"
    fi
  fi

  case "${AGENT}" in
    vibe)
      printf '%s\n' "${CONFIG_TEMPLATE_FILE}" > "${TRACE_DIR}/config-source.txt"
      printf '%s\n' "${RUN_DIR}/.vibe/config.toml" > "${TRACE_DIR}/run-config.txt"
      printf '%s\n' "${RUN_DIR}/.vibe/config.toml" > "${TRACE_DIR}/rendered-config-path.txt"
      cp "${RUN_DIR}/.vibe/config.toml" "${TRACE_DIR}/rendered-config.toml"
      printf '%s\n' "${RUN_DIR}/.vibe/prompts/${SYSTEM_PROMPT_ID}.md" > "${TRACE_DIR}/run-system-prompt.txt"
      if [[ -n "${PATCH_FILE}" ]]; then
        printf '%s\n' "${PATCH}" > "${TRACE_DIR}/agents-patch.txt"
        printf '%s\n' "${PATCH_FILE}" > "${TRACE_DIR}/agents-patch-source.txt"
      else
        printf '%s\n' "none" > "${TRACE_DIR}/agents-patch.txt"
      fi
      write_config_trace
      ;;
    claude-code)
      printf '%s\n' "${AUTOMATION_PROMPT}" > "${TRACE_DIR}/automation-system-prompt.txt"
      if [[ -f "${RUN_DIR}/CLAUDE.md" ]]; then
        printf '%s\n' "${RUN_DIR}/CLAUDE.md" > "${TRACE_DIR}/run-instructions.txt"
      else
        printf '%s\n' "none" > "${TRACE_DIR}/run-instructions.txt"
      fi
      if [[ -n "${PATCH_FILE}" ]]; then
        printf '%s\n' "${PATCH}" > "${TRACE_DIR}/claude-patch.txt"
        printf '%s\n' "${PATCH_FILE}" > "${TRACE_DIR}/claude-patch-source.txt"
      else
        printf '%s\n' "none" > "${TRACE_DIR}/claude-patch.txt"
      fi
      ;;
  esac

  write_install_checks
}

validate_artifacts() {
  local feature_json feature_dir spec_file checklist_file

  if [[ -z "${SKILL_COMMAND}" ]]; then
    if [[ ! -s "${TRACE_DIR}/agent-output.txt" ]]; then
      printf '%s direct run failed: missing or empty %s\n' "${ROLE}" "${TRACE_DIR}/agent-output.txt" >&2
      return 1
    fi
    return 0
  fi

  feature_json="${RUN_DIR}/.specify/feature.json"
  if [[ ! -f "${feature_json}" ]]; then
    printf '%s workflow failed: missing %s\n' "${ROLE}" "${feature_json}" >&2
    printf 'Expected the speckit-specify workflow to persist the active feature pointer.\n' >&2
    return 1
  fi

  feature_dir="$(sed -n 's/.*"feature_directory"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "${feature_json}" | head -n 1)"
  if [[ -z "${feature_dir}" ]]; then
    printf '%s workflow failed: %s does not contain feature_directory\n' "${ROLE}" "${feature_json}" >&2
    return 1
  fi

  spec_file="${RUN_DIR}/${feature_dir}/spec.md"
  checklist_file="${RUN_DIR}/${feature_dir}/checklists/requirements.md"

  [[ -f "${spec_file}" ]] || {
    printf '%s workflow failed: missing expected spec artifact %s\n' "${ROLE}" "${spec_file}" >&2
    return 1
  }

  [[ -f "${checklist_file}" ]] || {
    printf '%s workflow failed: missing expected checklist artifact %s\n' "${ROLE}" "${checklist_file}" >&2
    return 1
  }
}

run_agent() {
  case "${AGENT}" in
    vibe)
      (
        cd "${RUN_DIR}"
        VIBE_HOME="${RUN_DIR}/.vibe" vibe -p "${AGENT_PROMPT}" --trust --agent auto-approve --output "${OUTPUT_FORMAT}"
      ) 2>&1 | tee "${TRACE_DIR}/agent-output.txt"
      ;;
    claude-code)
      (
        cd "${RUN_DIR}"
        claude -p "${AGENT_PROMPT}" --append-system-prompt "${AUTOMATION_PROMPT}" --model "${MODEL}" --permission-mode bypassPermissions --output-format "${OUTPUT_FORMAT}"
      ) 2>&1 | tee "${TRACE_DIR}/agent-output.txt"
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)
      require_arg "$1" "${2:-}"
      CLI_ROLE="${2}"
      shift 2
      ;;
    --agent)
      require_arg "$1" "${2:-}"
      CLI_AGENT="${2}"
      shift 2
      ;;
    --id)
      require_arg "$1" "${2:-}"
      CLI_RUN_ID="${2}"
      shift 2
      ;;
    --prompt)
      require_arg "$1" "${2:-}"
      CLI_SCENARIO_PROMPT="${2}"
      shift 2
      ;;
    --skill)
      require_arg "$1" "${2:-}"
      CLI_SKILL_COMMAND="${2}"
      shift 2
      ;;
    --no-skill)
      CLI_NO_SKILL=1
      shift
      ;;
    --patch|--candidate-patch|--agents-patch|--claude-patch)
      require_arg "$1" "${2:-}"
      CLI_PATCH="${2}"
      shift 2
      ;;
    --config|--config-template)
      require_arg "$1" "${2:-}"
      CLI_CONFIG_TEMPLATE="${2}"
      shift 2
      ;;
    --config-var)
      require_arg "$1" "${2:-}"
      CLI_CONFIG_VARS+=("${2}")
      shift 2
      ;;
    --experiment)
      require_arg "$1" "${2:-}"
      CLI_EXPERIMENT_FILE="${2}"
      shift 2
      ;;
    --model)
      require_arg "$1" "${2:-}"
      CLI_MODEL="${2}"
      shift 2
      ;;
    --system-prompt)
      require_arg "$1" "${2:-}"
      CLI_SYSTEM_PROMPT="${2}"
      shift 2
      ;;
    --output)
      require_arg "$1" "${2:-}"
      CLI_OUTPUT_FORMAT="${2}"
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

load_experiment_manifest

MANIFEST_ROLE="${ROLE:-}"
MANIFEST_AGENT="${AGENT:-}"
MANIFEST_RUN_ID="${RUN_ID:-}"
MANIFEST_SCENARIO_PROMPT="${SCENARIO_PROMPT:-}"
MANIFEST_SKILL_COMMAND="${SKILL_COMMAND:-}"
MANIFEST_PATCH="${PATCH:-}"
MANIFEST_OUTPUT_FORMAT="${OUTPUT_FORMAT:-}"
MANIFEST_MODEL="${MODEL:-}"
MANIFEST_SYSTEM_PROMPT="${SYSTEM_PROMPT:-}"
MANIFEST_CONFIG_TEMPLATE="${CONFIG_TEMPLATE:-}"

AGENT="${CLI_AGENT:-${MANIFEST_AGENT:-}}"
[[ -n "${AGENT}" ]] || {
  printf 'Missing required --agent AGENT or AGENT in --experiment\n\n' >&2
  usage >&2
  exit 2
}

configure_agent_defaults

ROLE="${CLI_ROLE:-${MANIFEST_ROLE:-}}"
RUN_ID="${CLI_RUN_ID:-${MANIFEST_RUN_ID:-}}"
SCENARIO_PROMPT="${CLI_SCENARIO_PROMPT:-${MANIFEST_SCENARIO_PROMPT:-}}"
SKILL_COMMAND="${CLI_SKILL_COMMAND:-${MANIFEST_SKILL_COMMAND:-/speckit-specify}}"
if [[ "${CLI_NO_SKILL}" -eq 1 || "${SKILL_COMMAND}" == "none" || "${SKILL_COMMAND}" == "NONE" || "${SKILL_COMMAND}" == "no-skill" ]]; then
  SKILL_COMMAND=""
  NO_SKILL=1
  AUTOMATION_PROMPT="${DIRECT_AUTOMATION_PROMPT}"
else
  AUTOMATION_PROMPT="${SPEC_KIT_AUTOMATION_PROMPT}"
fi
PATCH="${CLI_PATCH:-${MANIFEST_PATCH:-}}"
OUTPUT_FORMAT="${CLI_OUTPUT_FORMAT:-${MANIFEST_OUTPUT_FORMAT:-${DEFAULT_OUTPUT_FORMAT}}}"
MODEL="${CLI_MODEL:-${MANIFEST_MODEL:-${DEFAULT_MODEL}}}"
SYSTEM_PROMPT="${CLI_SYSTEM_PROMPT:-${MANIFEST_SYSTEM_PROMPT:-${DEFAULT_SYSTEM_PROMPT}}}"
CONFIG_TEMPLATE_FILE="${CLI_CONFIG_TEMPLATE:-${MANIFEST_CONFIG_TEMPLATE:-${CONFIG_TEMPLATE}}}"

case "${ROLE}" in
  baseline|candidate)
    ;;
  "")
    printf 'Missing required --role baseline|candidate or ROLE in --experiment\n\n' >&2
    usage >&2
    exit 2
    ;;
  *)
    printf 'Invalid role: %s\n' "${ROLE}" >&2
    printf 'Supported roles: baseline, candidate\n' >&2
    exit 1
    ;;
esac

if ! value_in_list "${OUTPUT_FORMAT}" "${SUPPORTED_OUTPUT_FORMATS[@]}"; then
  printf 'Invalid output format for %s: %s\n' "${AGENT}" "${OUTPUT_FORMAT}" >&2
  printf 'Supported output formats:\n' >&2
  printf '  %s\n' "${SUPPORTED_OUTPUT_FORMATS[@]}" >&2
  exit 1
fi

resolve_system_prompt
if [[ -n "${CONFIG_TEMPLATE_FILE}" ]]; then
  if ! CONFIG_TEMPLATE_FILE="$(resolve_file "${CONFIG_TEMPLATE_FILE}")"; then
    printf 'Missing config template for %s: %s\n' "${AGENT}" "${CONFIG_TEMPLATE_FILE}" >&2
    exit 1
  fi
fi

rebuild_config_vars

if [[ -n "${PATCH}" ]]; then
  if [[ "${PATCH}" == */* ]]; then
    printf 'Patch must be a filename under %s/%s, got: %s\n' "${PROMPT_PATCHES_DIR}" "${AGENT}" "${PATCH}" >&2
    exit 1
  fi

  PATCH_FILE="${PROMPT_PATCHES_DIR}/${AGENT}/${PATCH}"
  [[ -f "${PATCH_FILE}" ]] || {
    printf 'Missing prepared patch: %s\n' "${PATCH_FILE}" >&2
    exit 1
  }
else
  PATCH_FILE=""
fi

case "${ROLE}" in
  baseline)
    RUNS_DIR="${BENCHMARK_DIR}/6-runs/1-baseline/${AGENT}"
    ;;
  candidate)
    RUNS_DIR="${BENCHMARK_DIR}/6-runs/2-candidate/${AGENT}"
    ;;
esac

if [[ -z "${RUN_ID}" ]]; then
  RUN_ID="$(next_run_id)"
fi

RUN_DIR="${RUNS_DIR}/${RUN_ID}"
if [[ -e "${RUN_DIR}" ]]; then
  printf 'Run directory already exists, refusing to overwrite: %s\n' "${RUN_DIR}" >&2
  exit 1
fi

if [[ "${NO_SKILL}" -eq 1 ]]; then
  SPECIFY_PATH="not-used"
  SPECIFY_VERSION="not-used"
else
  require_cli specify SPECIFY_PATH SPECIFY_VERSION
fi
require_cli "${AGENT_CLI}" AGENT_CLI_PATH AGENT_CLI_VERSION

rebuild_config_vars

if [[ -n "${SKILL_COMMAND}" && -n "${SCENARIO_PROMPT}" ]]; then
  AGENT_PROMPT="${SKILL_COMMAND} ${SCENARIO_PROMPT}"
else
  AGENT_PROMPT="${SCENARIO_PROMPT}"
fi

mkdir -p "${RUN_DIR}"

(
  cd "${RUN_DIR}"
  if [[ "${NO_SKILL}" -eq 0 ]]; then
    specify init --integration "${SPECIFY_INTEGRATION}" --script sh --here --force --no-git
  fi
)

if [[ -n "${PATCH_FILE}" ]]; then
  if [[ "${NO_SKILL}" -eq 1 && ! -f "${RUN_DIR}/${PATCH_TARGET}" ]]; then
    : > "${RUN_DIR}/${PATCH_TARGET}"
  fi
  append_patch
fi

prepare_agent_runtime
write_prompt_trace

printf 'Prepared %s run: %s\n' "${ROLE}" "${RUN_DIR}"
printf 'Agent: %s\n' "${AGENT}"
printf 'Model: %s\n' "${MODEL:-none}"
if [[ "${SYSTEM_PROMPT_SOURCE}" != "none" ]]; then
  printf 'System prompt: %s\n' "${SYSTEM_PROMPT_SOURCE}"
fi
if [[ -n "${EXPERIMENT_FILE}" ]]; then
  printf 'Experiment: %s\n' "${EXPERIMENT_FILE}"
fi

case "${AGENT}" in
  vibe)
    printf 'Vibe config: %s\n' "${RUN_DIR}/.vibe/config.toml"
    printf 'Vibe home: %s\n' "${RUN_DIR}/.vibe"
    ;;
  claude-code)
    if [[ -f "${RUN_DIR}/CLAUDE.md" ]]; then
      printf 'Claude instructions: %s\n' "${RUN_DIR}/CLAUDE.md"
    else
      printf 'Claude instructions: none\n'
    fi
    ;;
esac

if [[ "${SETUP_ONLY}" -eq 1 ]]; then
  exit 0
fi

if [[ -z "${SCENARIO_PROMPT}" ]]; then
  printf 'No --prompt provided. %s run is prepared but %s was not called.\n' "${ROLE}" "${AGENT}" >&2
  exit 0
fi

run_agent
validate_artifacts
