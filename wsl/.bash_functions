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