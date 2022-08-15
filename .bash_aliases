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

git_dir_def='--git-dir="~/bash-alias-sync/.git" \
--work-tree="~/bash-alias-sync"'

alias alias-pull="git ${git_dir_def} pull --rebase"

alias alias-push="git ${git_dir_def} add -A && \
                  git ${git_dir_def} commit -m 'Sync aliases' && \
                  git ${git_dir_def} pull --rebase && \
                  git ${git_dir_def} push"