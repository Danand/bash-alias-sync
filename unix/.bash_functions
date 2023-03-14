#!/bin/bash

function rg-fzf() {
  results="$(rg "$1" --files-without-match)"
  echo "${results}" | sort --uniq | fzf
}

function find-fzf() {
  results="$(find "$@")"
  echo "${results}" | sort --uniq | fzf
}

function git-history-fzf() {
  path="$1"

  commit=$(git log --format="%h^%s^%aN" --full-diff -- "${path}" | column -t -s "^" | fzf | cut -d " " -f 1)

  echo -e "\nShow diff for commit ${commit}\n\n"

  if [ -n "${commit}" ]; then
    git diff "${commit}^" "${commit}" -- "${path}"
  fi
}
