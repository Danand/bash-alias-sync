#!/bin/bash

function alias-update() {
  if [ -f "${HOME}/.bash_profile" ]; then
    source "${HOME}/.bash_profile"
  else
    source "${HOME}/.bashrc"
  fi
}

function alias-pull() {
  current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO" || exit 2
  git pull --rebase --autostash
  alias-update
  cd "${current_dir}" || exit 2
}

function alias-push() {
  current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO" || exit 2
  git pull --rebase --autostash
  git add -A
  git commit -m "Change aliases"
  git push
  alias-update
  cd "${current_dir}" || exit 2
}

function alias-reset() {
  current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO" || exit 2
  git reset --hard
  git clean -fd
  alias-update
  cd "${current_dir}" || exit 2
}
