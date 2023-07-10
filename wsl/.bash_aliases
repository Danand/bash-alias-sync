#!/bin/bash

alias git-cd-superproject='cd "$(wslpath "$(git rev-parse --show-superproject-working-tree)")"'
alias unity-log='echo $(wslpath $(wslvar USERPROFILE))/AppData/Local/Unity/Editor/Editor.log'
alias unity-log-clear='sudo cat /dev/null > $(wslpath $(wslvar USERPROFILE))/AppData/Local/Unity/Editor/Editor.log'
alias explorer-here='explorer.exe $(wslpath -w .)'
