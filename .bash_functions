#!/bin/bash
#
# Functions for sharing during loading of aliases.

function alias-update() {
  touch "${UPDATE_MARKER_FILE}"

  if [ -f "${HOME}/.bash_profile" ]; then
    # shellcheck source=/dev/null
    source "${HOME}/.bash_profile"
  else
    # shellcheck source=/dev/null
    source "${HOME}/.bashrc"
  fi
}

function alias-pull() {
  pushd "$BASH_ALIAS_SYNC_REPO" > /dev/null || return 2

  git pull --rebase --autostash
  alias-update

  popd > /dev/null || return 2
}

function alias-push() {
  pushd "$BASH_ALIAS_SYNC_REPO" > /dev/null || return 2

  git pull --rebase --autostash
  git add -A
  git commit -m "Change aliases"
  git push

  alias-update

  popd > /dev/null || return 2
}

function alias-reset() {
  pushd "$BASH_ALIAS_SYNC_REPO" > /dev/null || return 2

  git reset --hard
  git clean -fd

  alias-update

  popd > /dev/null || return 2
}
