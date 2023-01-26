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

  function explorerw() {
    win_path=$(wslpath -w "$1")
    explorer "${win_path}"
  }

  function riderw() {
    win_path=$(wslpath -w "$1")
    rider64.exe "${win_path}" &
  }
