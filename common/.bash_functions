#!/bin/bash

function alias-update() {
  source ~/.bashrc
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
