#!/bin/bash
#
# Contains aliases to add into `~/.bashrc` or `~/.bash_profile`.

function apply_aliases() {
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_aliases"
  source "$BASH_ALIAS_SYNC_REPO/$1/.bash_functions"
  source "$BASH_ALIAS_SYNC_REPO/$1/.git_aliases"
}

case "$OSTYPE" in
  darwin*)  apply_aliases "unix"; apply_aliases "macos" ;; 
  linux*)   apply_aliases "unix"; apply_aliases "linux";;
  msys*)    apply_aliases "mingw" ;;
esac

if cat /proc/version | grep -q microsoft ; then
  apply_aliases "wsl"
fi

apply_aliases "common"
