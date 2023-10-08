#!/bin/bash

alias mongod-default='mongod --dbpath /var/lib/mongo --logpath /var/log/mongodb/mongod.log --fork'

alias git-stage-fzf='git add $(git diff --name-only | fzf)'
alias git-unstage-fzf='git reset -- $(git diff --name-only --cached | fzf)'
alias git-rebase-fzf='git rebase --autostash $(git branch --format="%(refname:short)" | fzf)'
alias git-merge-fzf='git merge $(git branch --format="%(refname:short)" | fzf) --no-ff'
alias git-branch-rm-fzf='git branch -D $(git branch --format="%(refname:short)" | fzf)'
