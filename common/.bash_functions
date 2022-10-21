#!/bin/bash

function alias-pull() {
  current_dir=$(pwd)
  cd ~/bash-alias-sync
  git pull --rebase --autostash
  alias-update
  cd "${current_dir}"
}

function alias-push() {
  current_dir=$(pwd)
  cd ~/bash-alias-sync
  git pull --rebase --autostash
  git add -A
  git commit -m "Change aliases"
  git push
  alias-update
  cd "${current_dir}"
}
