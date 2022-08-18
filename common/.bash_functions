#!/bin/bash

function alias-pull() {
  cd ~/bash-alias-sync
  git pull --rebase --autostash
  source ~/.bashrc
}

function alias-push() {
  alias-pull
  cd ~/bash-alias-sync
  git add -A
  git commit -m "Change aliases"
  git push
  source ~/.bashrc
}