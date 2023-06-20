#!/bin/bash
#
# Loads aliases to add into `~/.bashrc` or `~/.bash_profile`.

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
}

# EXECUTION

if [ -f "${UPDATE_MARKER_FILE}" ]; then
  unset PROMPT
  unalias -a

  __undeclare_all
  __untrap_all

  rm -f "${UPDATE_MARKER_FILE}"
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

if grep -q "microsoft" "/proc/version" && test ! -f ".dockerenv"; then
  __apply_aliases "wsl"
fi

__export_functions
