#!/bin/bash

alias mongod-default='mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork'

alias docker-prune='yes | docker system prune --force'
alias docker-stop='docker rm $(docker ps -a -q)'
alias docker-log='docker logs --follow --timestamps --details'
alias docker-log-pipe='docker logs --follow --timestamps --details $(cat)'
alias docker-log-select='docker logs --follow --timestamps --details $(docker container ls | fzf | cut -d " " -f 1)'

alias git-stage='git add $(git diff --name-only | fzf)'
alias git-unstage='git reset -- $(git diff --name-only --cached | fzf)'
alias git-checkout='git checkout $(git branch --format="%(refname:short)" | sed "s/origin\///" | fzf)'
alias git-branch-rm='git branch -D $(git branch --format="%(refname:short)" | fzf)'
alias git-cd-submodule='cd "$(git submodule | cut -d " " -f 3 | fzf)"'