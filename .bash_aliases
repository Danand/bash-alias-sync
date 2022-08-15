#!/bin/bash
#
# Contains aliases to add into `~/.bashrc` or `~/.bash_profile`.

function apply_aliases() {
  source ~/bash-alias-sync/$1/.bash_aliases
  source ~/bash-alias-sync/$1/.bash_functions
}

apply_aliases "common"

case "$OSTYPE" in
  darwin*)  apply_aliases "unix"; apply_aliases "macos" ;; 
  linux*)   apply_aliases "unix"; apply_aliases "linux";;
  msys*)    apply_aliases "mingw" ;;
esac

if cat /proc/version | grep -q microsoft ; then
  apply_aliases "wsl"
fi

alias alias-pull='git --git-dir=~/bash-alias-sync/.git pull --rebase'

alias alias-push='git --git-dir="~/bash-alias-sync/.git" add -A && \
                  git --git-dir="~/bash-alias-sync/.git" commit -m "Sync aliases" && \
                  git --git-dir="~/bash-alias-sync/.git" pull --rebase && \
                  git --git-dir="~/bash-alias-sync/.git" push'