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

function pipe-temp() {
  data=$(cat)
  temp_file_path=$(mktemp)
  echo "${data}" > "${temp_file_path}"
  echo "${temp_file_path}"
}