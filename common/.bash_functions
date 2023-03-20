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

function non-existent-command-trap() {
  if [ "$?" == "127" ]; then
    echo "Let's pretend we did not see that..."
    history_last_line_number="$(history | tail -n 1 | grep -Po "^\s*(\K\d*)\s*")"
    history -d "${history_last_line_number}"
  fi
}

trap non-existent-command-trap ERR
