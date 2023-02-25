#!/bin/bash

alias alias-update='source ~/.bashrc'
alias alias-edit="code \"$BASH_ALIAS_SYNC_REPO\" --new-window"

alias mongod-default='mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork'

alias docker-prune='yes | docker system prune --force'
alias docker-kill='docker kill $(docker ps -q)'
alias docker-rm='docker rm $(docker ps -a -q)'
alias docker-log='docker-compose logs --follow --timestamps'
alias docker-log-pipe='docker-compose logs --follow --timestamps $(cat)'
alias docker-log-select='docker logs --follow --timestamps --details $(docker container ls | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-ignore-ls='rsync -avn . /dev/shm --exclude=.git --include-from=.dockerignore'

alias git-stage='git add $(git diff --name-only | fzf)'
alias git-unstage='git reset -- $(git diff --name-only --cached | fzf)'
alias git-checkout='git checkout $(git branch --format="%(refname:short)" | sed "s/origin\///" | fzf)'
alias git-rebase='git rebase --autostash $(git branch --format="%(refname:short)" | fzf)'
alias git-merge='git merge $(git branch --format="%(refname:short)" | fzf) --no-ff'
alias git-branch-rm='git branch -D $(git branch --format="%(refname:short)" | fzf)'
alias git-cd-submodule='cd "$(git submodule | cut -d " " -f 3 | fzf)"'
