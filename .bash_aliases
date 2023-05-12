#!/bin/bash
#
# Contains aliases to add into `~/.bashrc` or `~/.bash_profile`.

unset PROMPT

IFS=$'\n'
for declaration in $(declare -F); do
  options=$(echo "${declaration}" | cut -d " " -f 2)
  func=$(echo "${declaration}" | cut -d " " -f 3)

  if [ "${options}" == "-fx" ]; then
    unset -f "${func}"
  fi
done
unset IFS

trap -l | tr " " "\n" | cut -f 1 | grep -v ")" | xargs -I sig "${SHELL}" -c 'trap - sig'

function __export_functions() {
  for function_name in $(declare -F | grep -v "\-fx" | grep -v "\-f _" | cut -d ' ' -f 3); do
    export -f "${function_name?}"
  done
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

  __export_functions
}

unalias -a

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
