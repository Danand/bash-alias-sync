#!/bin/bash

export RG_SLASH='[/\\]{1}'

alias alias-edit="code \"$BASH_ALIAS_SYNC_REPO\" --new-window"

alias venv-create='DISPLAY= python3 -m venv .venv'
alias venv-activate='source ./venv/bin/activate'

alias git-fetch='git fetch --all && git submodule foreach git fetch --all'
alias git-cd-superproject='cd "$(git rev-parse --show-superproject-working-tree)"'

alias pip='DISPLAY= pip3'
alias python='python3'
alias venv-create='DISPLAY= python3 -m venv venv'
alias venv-activate='source ./.venv/bin/activate'

alias path-ls='echo $PATH | tr ":" "\n"'
alias col-first='echo "$(cat)" | cut -d " " -f 1'
alias untar='tar -zxvf'

alias dotnet-shutdown='dotnet build-server shutdown > /dev/null 2>&1'
