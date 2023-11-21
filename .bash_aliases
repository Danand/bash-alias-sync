#!/bin/bash
#
# Loads aliases for adding into `~/.bashrc` or `~/.bash_profile`.

# CONSTANTS

# shellcheck source=/dev/null
source "${BASH_ALIAS_SYNC_REPO}/.bash_constants"

# FUNCTIONS

function __undeclare_all() {
  IFS=$'\n'
  for declaration in $(declare -F); do
    options=$(echo "${declaration}" | cut -d " " -f 2)
    func=$(echo "${declaration}" | cut -d " " -f 3)

    if [ "${options}" == "-fx" ]; then
      unset -f "${func}"
    fi
  done
  unset IFS
}

function __untrap_all() {
  trap -l \
  | tr " " "\n" \
  | cut -f 1 \
  | grep -v ")" \
  | xargs \
    -I sig "${SHELL}" \
    -c 'trap - sig'
}

function __export_functions() {
  function_names="$( \
    declare -F \
    | grep -v "\-fx" \
    | grep -v "\-f _" \
    | cut -d ' ' -f 3 \
  )"

  IFS=$'\n'
  for function_name in ${function_names}; do
    export -f "${function_name?}"
  done
  unset IFS
}

function __apply_aliases() {
  # shellcheck source=/dev/null
  source "${BASH_ALIAS_SYNC_REPO}/$1/.bash_aliases"

  # shellcheck source=/dev/null
  source "${BASH_ALIAS_SYNC_REPO}/$1/.bash_functions"

  # shellcheck source=/dev/null
  source "${BASH_ALIAS_SYNC_REPO}/$1/.bash_handlers"

  # shellcheck source=/dev/null
  source "${BASH_ALIAS_SYNC_REPO}/$1/.git_aliases"

  # shellcheck source=/dev/null
  source "${BASH_ALIAS_SYNC_REPO}/$1/.bash_constants"

  # shellcheck source=/dev/null
  source "${BASH_ALIAS_SYNC_REPO}/$1/.bash_overrides"

  local deps_lock_file="${BASH_ALIAS_SYNC_REPO}/$1/.bash_deps.lock"

  if [ ! -f "${deps_lock_file}" ]; then
    source "${BASH_ALIAS_SYNC_REPO}/$1/.bash_deps"
    touch "${deps_lock_file}"
  fi
}

function __contains() {
  local needles

  entries=($(cat))
  needles=("$@")

  for entry in "${entries[@]}"; do
    for needle in "${needles[@]}"; do
      if [ "${entry}" == "${needle}" ]; then
        return 0
      fi
    done
  done

  return 1
}

__SECRETS_EXCLUDE=( \
  "ARGV" \
  "COMMIT_MSG_FILE" \
  "COMMIT_SOURCE" \
  "GIT_DIR" \
  "GIT_PUSH_OPTION_" \
  "GIT_PUSH_OPTION_COUNT" \
  "NF" \
  "SHA1" \
  "SOB" \
)

export __SECRETS_EXCLUDE

function __check_tokens() {
  rg \
    --hidden \
    --glob '!.git' \
    --only-matching \
    --replace '$1' \
    --no-messages \
    --no-filename \
    --no-line-number \
    '\$+\{?([A-Z0-9_]+)\}?' \
    "${BASH_ALIAS_SYNC_REPO}" \
  | sort --uniq \
  | while read -r varname; do
      if \
        [ -z "${!varname}" ] \
        && ! echo "${__SECRETS_EXCLUDE[*]}" | __contains "${varname}" \
        && ! echo "${varname}" | grep -q '^[0-9]*$'
      then
        echo -e "${COLOR_YELLOW}warning: Variable is not set for the current session:${COLOR_CLEAR} \`${COLOR_CYAN}${varname}${COLOR_CLEAR}\`" 1>&2
        echo -e 1>&2
        echo -e "You can add it to \`${COLOR_CYAN}~/.bash_secrets${COLOR_CLEAR}\`:" 1>&2
        echo -e "  echo 'export ${varname}=\"YOUR-VALUE-HERE\"' >> ~/.bash_secrets" 1>&2
        echo -e 1>&2
      fi
    done
}

# EXECUTION

if [ -f "${UPDATE_MARKER_FILE}" ]; then
  unset PROMPT
  unalias -a

  __undeclare_all
  __untrap_all

  rm -f "${UPDATE_MARKER_FILE}"
fi

if [ -f "${BASH_PATH_FILE}" ]; then
  source "${BASH_PATH_FILE}"
else
  touch "${BASH_PATH_FILE}"
fi

if [ -f "${BASH_SECRETS_FILE}" ]; then
  source "${BASH_SECRETS_FILE}"
else
  touch "${BASH_SECRETS_FILE}"
fi

# shellcheck source=/dev/null
source "${BASH_ALIAS_SYNC_REPO}/.bash_functions"

__apply_aliases "common"
__apply_aliases "unix"

if [[ "${OSTYPE}" == "darwin"* ]]; then
  __apply_aliases "macos"
elif [[ "${OSTYPE}" == "linux"* ]]; then
  __apply_aliases "linux"
fi

if [[ "${OSTYPE}" == "msys"* ]]; then
  __apply_aliases "mingw"
fi

if [ -f /proc/version ] && grep -q "microsoft" "/proc/version" && test ! -f ".dockerenv"; then
  __apply_aliases "wsl"
fi

__export_functions

if [ -f "${BASH_OVERRIDES_FILE}" ]; then
  source "${BASH_OVERRIDES_FILE}"
else
  touch "${BASH_OVERRIDES_FILE}"
fi

__check_tokens
