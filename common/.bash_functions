#!/bin/bash

function alias-pull() {
  current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO"
  git pull --rebase --autostash
  alias-update
  cd "${current_dir}"
}

function alias-push() {
  current_dir=$(pwd)
  cd "$BASH_ALIAS_SYNC_REPO"
  git pull --rebase --autostash
  git add -A
  git commit -m "Change aliases"
  git push
  alias-update
  cd "${current_dir}"
}

function mktemp-pipe() {
  checksum=$(echo "!!" | sha1sum | head -c 40)

  data=$(cat)

  touch "${HOME}/.mktemp_history"

  if mktemp-check $checksum; then
    temp_file_path=$(mktemp-get $checksum)
  else
    temp_file_path=$(mktemp)

    echo "${data}" > "${temp_file_path}"
    echo -e "${checksum}\t${temp_file_path}" >> "${HOME}/.mktemp_history"
  fi

  echo "${temp_file_path}"
}

function mktemp-check() {
  checksum=$1
  cat "${HOME}/.mktemp_history" | grep -q "^${checksum}"
  return_code=$?
  echo "Check result exit code: ${return_code}, checksum: ${checksum}" 1>&2
  return $return_code
}

function mktemp-get() {
  checksum=$1
  cat "${HOME}/.mktemp_history" | grep "^${checksum}" | tail -n 1 | cut -f 2
}

function cat-pipe() {
  cat "$(cat)"
}

function mktemp-last() {
  cat "${HOME}/.mktemp_history" | tail -n 1
}
