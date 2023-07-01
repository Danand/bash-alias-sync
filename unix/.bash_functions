#!/bin/bash

function rg-fzf() {
  local results="$(rg "$1" --files-without-match)"
  echo "${results}" | sort --uniq | fzf
}

function find-fzf() {
  local results="$(find "$@")"
  echo "${results}" | sort --uniq | fzf
}

function git-history-fzf() {
  local path="$1"

  local commit=$(git log --format="%h^%s^%aN" --full-diff -- "${path}" | column -t -s "^" | fzf | cut -d " " -f 1)

  echo -e "\nShow diff for commit ${commit}\n\n"

  if [ -n "${commit}" ]; then
    git diff "${commit}^" "${commit}" -- "${path}"
  fi
}

function git-cd-submodule-fzf() {
  cd "$("$(which git)" submodule --quiet foreach --recursive pwd | xargs realpath --relative-to="${PWD}" | fzf)" || return 2
}

function git-merge-fzf() {
  local pattern="$1"

  local branches

  if [ -z "${pattern}" ]; then
    branches="$(git branch -r --format="%(refname:short)")"
  else
    branches="$(git branch -r --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  slocal elected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git merge --no-ff "${selected_branch}"
}

function git-rebase-current-branch-fzf() {
  local pattern="$1"

  local branches

  if [ -z "${pattern}" ]; then
    branches="$(git branch --format="%(refname:short)")"
  else
    branches="$(git branch --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  local ours_branch="$(git branch --show-current)"
  local ours_first_commit=$(git-branch-first-commit)

  git rebase -i --autostash --onto "${selected_branch}" "${ours_first_commit}^" "HEAD"
  git update-ref "refs/heads/${ours_branch}" HEAD
  git checkout "${ours_branch}"
}

function git-rebase-from-rev-fzf() {
  git log --oneline \
  | fzf \
  | cut -d " " -f 1 \
  | git rev-list --count "$(cat)..HEAD" \
  | echo $(($(cat) + 1)) \
  | git rebase -i --autostash "HEAD~$(cat)"
}

function git-checkout-fzf() {
  local pattern="$1"

  local branches

  if [ -z "${pattern}" ]; then
    branches="$(git branch --format="%(refname:short)")"
  else
    branches="$(git branch --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git checkout \
    --force \
    --recurse-submodules \
    "${selected_branch}"
}

function git-checkout-file-fzf() {
  local pattern="$1"

  local branches

  if [ -z "${pattern}" ]; then
    branches="$(git branch -r --format="%(refname:short)")"
  else
    branches="$(git branch -r --format="%(refname:short)" | grep "${pattern}")"
  fi

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  local selected_file=""
  local selected_dir="."

  while [ -z "${selected_file}" ]; do
    local selected_item="$(git ls-tree --format="%(objecttype)%x09%(path)" "${selected_branch}" "${selected_dir}/" | fzf)"

    local selected_item_type=$(echo "${selected_item}" | cut -f 1)
    local selected_item_name=$(echo "${selected_item}" | cut -f 2)

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

function git-conflict-resolve-fzf() {
  local file

  file="$( \
    git diff \
      --name-only \
      --diff-filter="U" \
    | fzf \
  )"

  if [ -z "${file}" ]; then
    return 1
  fi

  local option

  # shellcheck disable=SC2046
  option="$(
    echo -e "theirs\nours\nmergetool" \
    | fzf \
  )"

  # shellcheck disable=SC2154
  if [ -z "${option}" ]; then
    return 1
  fi

  if [ "${option}" == "mergetool" ]; then
    git mergetool "${file}"
  else
    # shellcheck disable=SC2086
    git checkout --$option "${file}"
  fi

  git add "${file}"
}

function docker-compose-logs() {
  docker-compose "$@" logs --follow --timestamps
}

function docker-compose-logs-pipe() {
  docker-compose "$@" logs --follow --timestamps "$(cat)"
}

function docker-run-it-fzf() {
  local selected_image_line
  selected_image_line="$(docker image ls | tail -n +2 | fzf | tr -s ' ')"

  local image_name

  image_name="$(echo "${selected_image_line}" | cut -d ' ' -f 1)"
  image_name+=":"
  image_name+="$(echo "${selected_image_line}" | cut -d ' ' -f 2)"

  docker run -it "${image_name}" "$@"
}

function ffmpeg-speedup() {
  local speed
  speed=$(bc -l <<< "scale=2; 1/$2")
  ffmpeg -i "$1" -filter:v "setpts=${speed}*PTS" "${@:3}" "speed-up-$1"
}

function venv-init() {
  python -m venv .venv

  # shellcheck source=/dev/null
  source ".venv/bin/activate"

  pip install --upgrade pip

  local requirements="./requirements.txt"

  if [ -f "${requirements}" ]; then
    pip install -r "${requirements}"
  fi
}

function uniq-unsorted() {
  local index=0

  while read -r entry; do
    echo -e "$((index=index+1))\t${entry}"
  done \
  | sort \
    --uniq \
    -k 2 \
  | sort \
    -k 1 \
    -n \
  | cut \
    -f 2
}

function recall() {
  local entry

  # shellcheck disable=SC2002
  entry="$( \
    builtin history -w "/dev/stdout" \
    | tac <(cat) \
    | uniq-unsorted \
    | fzf \
  )"

  read -i "${entry}" -er input

  # shellcheck disable=SC2154
  eval "${input}" \
  && builtin history -s "${input}"
}

function adb-stream() {
  adb exec-out screenrecord \
    --output-format="h264" \
    - \
  | ffplay \
    -y 960 \
    -framerate 60 \
    -probesize 32 \
    -sync "video" \
    -
}

function adb-install-fzf() {
  find . -type f -name "*.apk" \
  | fzf \
  | adb install -r "$(cat)"
}

function adb-logcat-fzf() {
  adb shell "pm list packages" \
  | cut -d ":" -f 2 \
  | fzf \
  | adb shell "pidof $(cat)" \
  | adb logcat --pid="$(cat)"
}

function adb-sensor-ls() {
  adb shell dumpsys sensorservice \
  | grep "android\.sensor" \
  | cut -d "|" -f 4 \
  | cut -d "." -f 3 \
  | cut -d "(" -f 1 \
  | sort --uniq
}
