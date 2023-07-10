#!/bin/bash

# shellcheck disable=SC2139

alias git-cd-superproject='cd "$(git rev-parse --show-superproject-working-tree)"'

alias path-ls='echo ${PATH} | tr ":" "\n"'
alias col-first='echo "$(cat)" | cut -d " " -f 1'
alias untar='tar -zxvf'

alias dotnet-shutdown='dotnet build-server shutdown > /dev/null 2>&1'
