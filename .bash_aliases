#!/bin/bash
#
# Contains aliases to add into `~/.bashrc` or `~/.bash_profile`.

function export_functions() {
  for function_name in $(declare -F | grep -v "\-fx" | grep -v "\-f _" | cut -d ' ' -f 3); do
    export -f "${function_name?}"
  done
}

function apply_aliases() {
  # shellcheck source=/dev/null
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_aliases"

  # shellcheck source=/dev/null
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_functions"

  # shellcheck source=/dev/null
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_handlers"

  # shellcheck source=/dev/null
  source "$BASH_ALIAS_SYNC_REPO/$1/.git_aliases"

  export_functions
}

unalias -a

apply_aliases "common"
apply_aliases "unix"

case "$OSTYPE" in
  darwin*)  apply_aliases "macos" ;;
  linux*)   apply_aliases "linux";;
  msys*)    apply_aliases "mingw" ;;
esac

if grep -q "microsoft" "/proc/version" && ! test -f ".dockerenv"; then
  apply_aliases "wsl"
fi
