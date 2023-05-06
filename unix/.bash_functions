#!/bin/bash

function git-branch-first-commit() {
  branch="$(git branch --show-current)"

  last_commit="HEAD"

  for commit in $(git log "${branch}" --oneline --format=%H); do
    if [ "$(git branch --contains "${commit}" | wc -l)" -gt 1 ]; then
      echo "${last_commit}"
      return 0
    fi
    last_commit="${commit}"
  done
}

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

function git-cd-submodule-fzf() {
  cd "$("$(which git)" submodule --quiet foreach --recursive pwd | xargs realpath --relative-to="${PWD}" | fzf)" || return 2
}

function git-merge-fzf() {
  pattern="$1"

  if [ -z "${pattern}" ]; then
    branches="$(git branch -r --format="%(refname:short)")"
  else
    branches="$(git branch -r --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git merge --no-ff "${selected_branch}"
}

function git-rebase-current-branch-fzf() {
  pattern="$1"

  if [ -z "${pattern}" ]; then
    branches="$(git branch --format="%(refname:short)")"
  else
    branches="$(git branch --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  ours_branch="$(git branch --show-current)"
  ours_first_commit=$(git-branch-first-commit)

  git rebase -i --autostash --onto "${selected_branch}" "${ours_first_commit}^" "HEAD"
  git update-ref "refs/heads/${ours_branch}" HEAD
  git checkout "${ours_branch}"
}

function git-checkout-fzf() {
  pattern="$1"

  if [ -z "${pattern}" ]; then
    branches="$(git branch --format="%(refname:short)")"
  else
    branches="$(git branch --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git checkout "${@:2}" "${selected_branch}"
}

function git-checkout-file-fzf() {
  pattern="$1"

  if [ -z "${pattern}" ]; then
    branches="$(git branch -r --format="%(refname:short)")"
  else
    branches="$(git branch -r --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  selected_dir="."
  selected_file=""

  while [ -z "${selected_file}" ]; do
    selected_item="$(git ls-tree --format="%(objecttype)%x09%(path)" "${selected_branch}" "${selected_dir}/" | fzf)"

    selected_item_type=$(echo "${selected_item}" | cut -f 1)
    selected_item_name=$(echo "${selected_item}" | cut -f 2)

    if [ "${selected_item_type}" == "blob" ]; then
      selected_file="${selected_item_name}"
    elif [ "${selected_item_type}" == "tree" ]; then
      selected_dir="${selected_item_name}"
    else
      1>&2 echo "Item type \`${selected_item_type}\` is currently not supported"
      return 1
    fi
  done

  git checkout "${selected_branch}" -- "${selected_file}"
}

function docker-logs() {
  docker-compose "$@" logs --follow --timestamps
}

function docker-logs-pipe() {
  docker-compose "$@" logs --follow --timestamps "$(cat)"
}

function docker-run-it-fzf() {
  selected_image_line="$(docker image ls | tail -n +2 | fzf | tr -s ' ')"

  image_name="$(echo "${selected_image_line}" | cut -d ' ' -f 1)"
  image_name+=":"
  image_name+="$(echo "${selected_image_line}" | cut -d ' ' -f 2)"

  docker run -it "${image_name}" "$@"
}

function ffmpeg-speedup() {
  speed=$(bc -l <<< "scale=2; 1/$2")
  ffmpeg -i "$1" -filter:v "setpts=${speed}*PTS" "${@:3}" "speed-up-$1"
}

function venv-init() {
  python -m venv .venv
  source .venv/bin/activate
  pip install --upgrade pip

  local requirements="./requirements.txt"

  if [ -f "${requirements}" ]; then
    pip install -r "${requirements}"
  fi
}

function git-chmod() {
  mod="$1"
  paths="$(ls -1a "$2")"

  IFS=$'\n'
  for path in ${paths}; do
    chmod "${mod}" "${path}"
    git update-index --chmod=${mod} "${path}" > /dev/null 2>&1 || \
    git add --chmod=${mod} "${path}" > /dev/null 2>&1
  done
  unset IFS
}
