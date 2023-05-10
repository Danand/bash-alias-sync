#!/bin/bash

function alias-update() {
  if [ -f "${HOME}/.bash_profile" ]; then
    source "${HOME}/.bash_profile"
  else
    source "${HOME}/.bashrc"
  fi
}

function alias-pull() {
  local current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO" || exit 2
  git pull --rebase --autostash
  alias-update
  cd "${current_dir}" || exit 2
}

function alias-push() {
  local current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO" || exit 2
  git pull --rebase --autostash
  git add -A
  git commit -m "Change aliases"
  git push
  alias-update
  cd "${current_dir}" || exit 2
}

function alias-reset() {
  local current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO" || exit 2
  git reset --hard
  git clean -fd
  alias-update
  cd "${current_dir}" || exit 2
}

function path-edit() {
  local tmp="$(mktemp)"
  echo $PATH | tr ":" "\n" > "${tmp}"
  code --new-window --wait "${tmp}"
  export PATH="$(cat "${tmp}" | tr "\n" ":")"
  rm -f "${tmp}"
}

function git-chmod() {
  local mod="$1"
  local paths="$(ls -1a "$2")"

  IFS=$'\n'
  for path in ${paths}; do
    chmod "${mod}" "${path}"
    git update-index --chmod=${mod} "${path}" > /dev/null 2>&1 || \
    git add --chmod=${mod} "${path}" > /dev/null 2>&1
  done
  unset IFS
}

function git-branch-first-commit() {
  local branch="$(git branch --show-current)"

  local last_commit="HEAD"

  for commit in $(git log "${branch}" --oneline --format=%H); do
    if [ "$(git branch --contains "${commit}" | wc -l)" -gt 1 ]; then
      echo "${last_commit}"
      return 0
    fi

    last_commit="${commit}"
  done
}

function git-reset-branches() {
  git branch --format "%(refname:short)" --quiet 2>/dev/null | while read -r branch; do
    if [ "${branch}" != "$(git branch --show-current)" ]; then
      git branch -D "${branch}" 2>/dev/null
    fi
  done

  git submodule foreach "${SHELL} -c ${FUNCNAME[0]}"
}
