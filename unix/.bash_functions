#!/bin/bash

function rg-fzf() {
  local results
   results="$(rg "$1" --files-without-match)"

  echo "${results}" | sort --uniq | fzf
}

function rg-code() {
  rg \
    --with-filename \
    --vimgrep \
    "$@" \
  | while IFS=':' read -r path line column _; do
      local path="${path//\\//}"
      local goto_spec="${path}:${line}:${column}"

      echo "Opening in VS Code: ${goto_spec}" 1>&2

      code \
        --reuse-window \
        --goto "${goto_spec}" \
      < /dev/null
    done
}

function find-fzf() {
  local results
  results="$(find "$@")"

  echo "${results}" | sort --uniq | fzf
}

function git-history-fzf() {
  local path="$1"

  local commit

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
  local branches

  branches="$(git branch -r --format="%(refname:short)")"

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
  local branches

  branches="$(git branch --format="%(refname:short)")"

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  local ours_branch
  ours_branch="$(git branch --show-current)"

  local ours_first_commit
  ours_first_commit=$(git-branch-first-commit)

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
  local branches

  branches="$(git branch --format="%(refname:short)")"

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git checkout \
    --force \
    --recurse-submodules \
    "${selected_branch}"
}

function git-checkout-remote-fzf() {
  local branches

  branches="$(git branch --remote --format="%(refname:short)" | cut -d "/" -f 2-)"

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git checkout \
    --force \
    --recurse-submodules \
    "${selected_branch}"
}

function git-checkout-file-fzf() {
  local branches

  branches="$(git branch -r --format="%(refname:short)")"

  if [ -z "${branches}" ]; then
    return 0
  fi

  local selected_branch

  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  local selected_file=""
  local selected_dir="."

  while [ -z "${selected_file}" ]; do
    local selected_item
    selected_item="$(git ls-tree --format="%(objecttype)%x09%(path)" "${selected_branch}" "${selected_dir}/" | fzf)"

    local selected_item_type
    selected_item_type=$(echo "${selected_item}" | cut -f 1)

    local selected_item_name
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

function git-commit-hours() {
  local hours="$1"

  shift

  local date_format="%Y-%m-%d %H:%M:%S"

  local target_date

  target_date="$(date --date="${hours} hours" +"${date_format}")"

  GIT_AUTHOR_DATE="${target_date}" \
  GIT_COMMITTER_DATE="${target_date}" \
  git commit "$@"
}

function git-fixup-hard() {
  tag="$(git describe --tags --exact-match HEAD 2>/dev/null || true)"

  git add -A
  git commit --amend --no-edit

  git push --force

  if [ -n "${tag}" ]; then
    git tag -f "${tag}"
    git push --tags --force
  fi
}

function docker-compose-logs() {
  docker-compose "$@" logs --follow --timestamps
}

function docker-compose-logs-pipe() {
  docker-compose "$@" logs --follow --timestamps "$(cat)"
}

function docker-run-it-fzf() {
  local selected_image_line

  selected_image_line="$( \
    docker image ls \
    | tail -n +2 \
    | fzf \
    | tr -s ' ' \
  )"

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

  builtin history -a
  builtin history -w

  # shellcheck disable=SC2002
  entry="$( \
    builtin history -w "/dev/stdout" \
    | cat \
    | uniq-unsorted \
    | fzf \
      --tac \
      --header="Pick line from history:" \
      --layout="reverse" \
      --no-sort \
      --height="33%" \
  )"

  builtin history -s "recall"

  if [ -z "${entry}" ]; then
    return 0
  fi

  read \
    -er \
    -i "${entry}" \
    -p "${PS1@P}" \
    input

  # shellcheck disable=SC2154
  eval "${input}" \
  && builtin history -s "${input}"

  builtin history -w
  builtin history -n
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

function ip-local() {
  ip -4 addr show \
  | awk '/inet / {print $2}' \
  | cut -d '/' -f1
}

function __kill_preview() {
  ps_line="$1"
  pstree -p "$(echo "${ps_line}" | awk '{print $1}')"
}

export -f __kill_preview

function kill-fzf() {
  ps -aex --format $'%p\t%a' \
  | tail -n +2 \
  | grep \
    -v \
    -e "ps -aex" \
    -e "tail" \
    -e "grep" \
  | column -t \
  | fzf \
    --tac \
    --header="Choose process to kill:" \
    --layout="reverse" \
    --no-sort \
    --preview="__kill_preview {}" \
    --preview-window 'right:33%' \
  | kill -9 "$(cat | awk '{print $1}')"
}

function du-fzf() {
  while true; do
    entry="$(du -hs -- * | sort -rh | fzf --tac)"
    path="$(echo "${entry}" | cut -f 2-)"

    if [ -d "$(realpath "${path}")" ]; then
      cd "${path}" || return 2
    fi
  done
}

function parse-as-table() {
  local pattern="$1"

  local input
  input="$(cat)"

  if [ ! $# -eq 1 ]; then
    echo "error: incorrect number of parameters" 1>&2
    return 1
  fi

  if [ -z "${pattern}" ]; then
    echo "error: given regex pattern is empty" 1>&2
    return 1
  fi

  echo "${input}" \
  | "${BASH_ALIAS_SYNC_REPO}/python-scripts/parse-as-table.py" "${pattern}"
}

function cut-math() {
  local operator="$1"

  local tmp_sum
  tmp_sum=$(mktemp -q)

  echo "0" > "${tmp_sum}"

  cat \
  | cut "${@:2}" \
  | while read -r value; do
      total="$(cat "${tmp_sum}")"
      result="$(awk "BEGIN {print ${value} ${operator} ${total}; exit}")"

      echo "${result}" > "${tmp_sum}"
    done

  cat "${tmp_sum}"

  rm -f "${tmp_sum}"
}

function sum() {
  cat | cut-math "+" "$@"
}

function avg() {
  local table
  table="$(cat)"

  local total
  total="$(echo "${table}" | sum "$@")"

  local count
  count="$(echo "${table}" | wc -l)"

  local result
  result="$(awk "BEGIN {print ${total} / ${count}; exit}")"

  echo "${result}"
}

function gh-runs-rm-fzf() {
  local repo

  repo="$(\
    gh repo list \
      --json "nameWithOwner" \
      --jq '.[] | .nameWithOwner' \
    | fzf \
  )"

  local username
  username="$(echo "${repo}" | cut -d "/" -f 1)"

  while true; do
    local run_id

    run_id="$( \
      gh run list \
        -R "${repo}" \
        --limit 100 \
        --json "databaseId,status,conclusion,workflowName,displayTitle,headBranch,updatedAt" \
        --jq '.[] | [ "\(.databaseId)", "\(.status)", "\(.conclusion)", "\(.workflowName)", "\(.displayTitle)", "\(.headBranch)", "\(.updatedAt)" ] | @tsv' \
      | column \
        -s $'\t' \
        -t \
      | fzf --tac \
      | cut \
        -d " " \
        -f 1
    )"

    if [ -z "${run_id}" ]; then
      break
    fi

    curl \
      -X "DELETE" \
      -H "Accept: application/vnd.github.v3+json" \
      -u "${username}:${GITHUB_TOKEN}" \
      "https://api.github.com/repos/${repo}/actions/runs/${run_id}"
  done
}

function docker-hub-token-bearer-obtain() {
  if [ -z "${DOCKERHUB_USERNAME}" ]; then
    DOCKERHUB_USERNAME="$(cat | cut -d "@" -f 1)"
  fi

  if [ -z "${DOCKERHUB_TOKEN}" ]; then
    DOCKERHUB_TOKEN="$(cat | cut -d "@" -f 2)"
  fi

  curl \
    -s \
    -X "POST" \
    -H "Content-Type: application/json" \
    -d "{ \"username\": \"${DOCKERHUB_USERNAME}\", \"password\": \"${DOCKERHUB_TOKEN}\" }" \
    "https://hub.docker.com/v2/users/login" \
  | jq -r '.token'
}

function docker-hub-repo-tag-ls() {
  if [ -z "${DOCKERHUB_BEARER}" ]; then
    DOCKERHUB_BEARER="$(docker-hub-token-bearer-obtain)"
    export DOCKERHUB_BEARER
  fi

  local image="$1"

  local namespace
  local repository

  if echo "${image}" | grep -q "/"; then
    namespace="$(echo "${image}" | cut -d "/" -f 1)"
    repository="$(echo "${image}" | cut -d "/" -f 2)"
  else
    namespace="library"
    repository="${image}"
  fi

  local response

  response="$( \
    curl \
      -s \
      -X "GET" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${bearer_token}" \
      "https://hub.docker.com/v2/namespaces/${namespace}/repositories/${repository}/tags"
  )"

  if [ "$(echo "${response}" | jq -r '.errinfo')" != "null" ]; then
    echo "${response}" 1>&2
    return 1
  fi

  echo "${response}"
}

function docker-hub-repo-tag-aliases() {
  local input="$1"

  local image
  image="$(echo "${input}" | cut -d ":" -f 1)"

  local tag
  tag="$(echo "${input}" | cut -d ":" -f 2)"

  local tags_json="$(docker-hub-repo-tag-ls "${image}")"

  local digest_needle

  digest_needle="$( \
    echo "${tags_json}" \
    | jq \
      -r \
      --arg tag "${tag}" \
      '.results | .[] | select(.name == $tag) | .digest' \
  )"

  echo "${tags_json}" \
  | jq \
    -r \
    --arg tag "${tag}" \
    --arg digest_needle "${digest_needle}" \
    '.results | .[] | select(.digest == $digest_needle and .name != $tag) | .name'
}

function docker-hub-repo-tag-latest() {
  local input="$1"
  docker-hub-repo-tag-aliases "${input}:latest"
}
