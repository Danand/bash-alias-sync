#!/bin/bash
#
# Contains aliases to add into `~/.bashrc` or `~/.bash_profile`.

function apply_aliases() {
  source ~/bash-alias-sync/$1/.bash_aliases
  source ~/bash-alias-sync/$1/.bash_functions
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
