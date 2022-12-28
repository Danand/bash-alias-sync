#!/bin/bash

alias clip='clip.exe'
alias explorer='explorer.exe'
alias cmd='cmd.exe'
alias git='git.exe'
alias git-cd-superproject='cd "$(wslpath "$(git rev-parse --show-superproject-working-tree)")"'
alias unity-log='echo $(wslpath $(wslvar USERPROFILE))/AppData/Local/Unity/Editor/Editor.log'
alias unity-log-clear='sudo cat /dev/null > $(wslpath $(wslvar USERPROFILE))/AppData/Local/Unity/Editor/Editor.log'
alias alias-edit='codew "$BASH_ALIAS_SYNC_REPO"'
alias explorer-here='explorer.exe $(wslpath -w .)'
