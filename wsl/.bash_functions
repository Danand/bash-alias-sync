#!/bin/bash

function codew() {
  if [ -z "$1" ]; then
    path="$(cat)"
  else
    path="$1"
  fi
  wait
  win_path=$(wslpath -w "${path}")
  cmd.exe /c code "${win_path}" --new-window 2>/dev/null
}

function codewr() {
  if [ -z "$1" ]; then
    path="$(cat)"
  else
    path="$1"
  fi
  wait
  win_path=$(wslpath -w "${path}")
  cmd.exe /c code "${win_path}" --reuse-window 2>/dev/null
}

function codewrg() {
  for path in $(rg -l "$1"); do
    codewr "${path}"
  done
}

function explorerw() {
  win_path=$(wslpath -w "$1")
  explorer "${win_path}"
}

function riderw() {
  win_path=$(wslpath -w "$1")
  rider64.exe "${win_path}" &
}

function ssh-keygenw() {
  ssh-keygen -q -t rsa -N '' -f "$HOME/.ssh/$1" <<<y > /dev/null
  user_profile_win="$(wslvar USERPROFILE)"
  user_profile_wsl="$(wslpath "${user_profile_win}")"
  cp -f "$HOME/.ssh/$1" "${user_profile_wsl}/.ssh/$1"
  cp -f "$HOME/.ssh/$1.pub" "${user_profile_wsl}/.ssh/$1.pub"
}
