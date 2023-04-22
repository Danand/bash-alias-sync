#!/bin/bash

# shellcheck disable=SC2139

alias alias-edit="code \"${BASH_ALIAS_SYNC_REPO}\" --new-window"

alias git-fetch='git fetch --all && git submodule foreach git fetch --all'
alias git-cd-superproject='cd "$(git rev-parse --show-superproject-working-tree)"'

alias path-ls='echo $PATH | tr ":" "\n"'
alias col-first='echo "$(cat)" | cut -d " " -f 1'
alias untar='tar -zxvf'

alias dotnet-shutdown='dotnet build-server shutdown > /dev/null 2>&1'
