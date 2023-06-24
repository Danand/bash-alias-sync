#!/bin/bash

alias adb-stream='adb exec-out screenrecord --output-format=h264 - | ffplay -y 960 -framerate 60 -probesize 32 -sync video -'
alias adb-install-fzf='find . -type f -name "*.apk" | fzf | adb install -r $(cat)'

alias mongod-default='mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork'

alias docker-prune='yes | docker system prune -a --force'
alias docker-stop-all='docker stop $(docker ps -q)'
alias docker-kill-all='docker kill $(docker ps -q)'
alias docker-rm-all='docker rm $(docker ps -a -q)'
alias docker-rmi-all='docker rmi -f $(docker images -aq)'
alias docker-logs-fzf='docker logs --follow --timestamps --details $(docker container ls | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-stats-fzf='docker stats $(docker ps | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-stop-fzf='docker stop $(docker ps | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-kill-fzf='docker kill $(docker ps | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-restart-fzf='docker restart $(docker ps -a | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-rm-fzf='docker rm $(docker ps -f "status=exited" | tail -n +2 | fzf | cut -d " " -f 1)'
alias docker-rmi-fzf='docker rmi -f $(docker image ls --format="{{.ID}}\t{{.Repository}}\t{{.Tag}}" | column -t | fzf | cut -d " " -f 1)'
alias docker-ignore-ls='rsync -avn . /dev/shm --exclude=.git --include-from=.dockerignore'

alias git-stage-fzf='git add $(git diff --name-only | fzf)'
alias git-unstage-fzf='git reset -- $(git diff --name-only --cached | fzf)'
alias git-rebase-fzf='git rebase --autostash $(git branch --format="%(refname:short)" | fzf)'
alias git-merge-fzf='git merge $(git branch --format="%(refname:short)" | fzf) --no-ff'
alias git-branch-rm-fzf='git branch -D $(git branch --format="%(refname:short)" | fzf)'

alias venv-create='python -m venv .venv'
alias venv-activate='source .venv/bin/activate'
alias venv-deactivate='deactivate'
alias venv-reset='rm -rf .venv'

alias pip-restore='pip install --require-virtualenv -r requirements.txt'
alias pip-uninstall-all='pip freeze | xargs pip uninstall --require-virtualenv -y'
alias pip-uninstall-fzf='pip freeze | fzf | pip uninstall $(cat) -y'
