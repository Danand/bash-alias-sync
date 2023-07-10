#!/bin/bash

function code-reuse() {
  local path

  if [ -z "$1" ]; then
    path="$(cat)"
  else
    path="$1"
  fi

  wait

  local win_path
  win_path=$(wslpath -w "${path}")

  cmd.exe /c code "${win_path}" --reuse-window 2>/dev/null
}

function code-rg() {
  for path in $(rg -l "$1"); do
    code "${path}"
  done
}

function code-touch() {
  touch "$1"
  code "$1" --reuse-window
}

function ssh-keygen-wsl() {
  ssh-keygen -q -t rsa -N '' -f "$HOME/.ssh/$1" <<<y > /dev/null

  local user_profile_win
  user_profile_win="$(wslvar USERPROFILE)"

  local user_profile_wsl
  user_profile_wsl="$(wslpath "${user_profile_win}")"

  cp -f "$HOME/.ssh/$1" "${user_profile_wsl}/.ssh/$1"
  cp -f "$HOME/.ssh/$1.pub" "${user_profile_wsl}/.ssh/$1.pub"
}
