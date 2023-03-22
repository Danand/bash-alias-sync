#!/bin/bash
#
# Contains aliases to add into `~/.bashrc` or `~/.bash_profile`.

function export_functions() {
  for function_name in $(declare -F | grep -v "\-fx" | grep -v "\-f _" | cut -d ' ' -f 3); do
    export -f "${function_name?}"
  done
}

function apply_aliases() {
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_aliases"
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_functions"
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_handlers"
  source "$BASH_ALIAS_SYNC_REPO/$1/.git_aliases"

  export_functions
}

unalias -a

case "$OSTYPE" in
  darwin*)  apply_aliases "unix"; apply_aliases "macos" ;;
  linux*)   apply_aliases "unix"; apply_aliases "linux";;
  msys*)    apply_aliases "mingw" ;;
esac

if grep -q "microsoft" "/proc/version" ; then
  apply_aliases "wsl"
fi

apply_aliases "common"
