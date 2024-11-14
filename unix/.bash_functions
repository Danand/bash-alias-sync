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

  local selected_branch
  selected_branch="$(echo "${branches}" | fzf)"

  if [ "$?" == "130" ] || [ -z "${selected_branch}" ]; then
    return 0
  fi

  git merge --no-ff "${selected_branch}"
}

function git-merge-remote-fzf() {
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
  git fetch-all

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

  git reset \
    --hard \
    "origin/${selected_branch}"

  git submodule update \
    --force \
    --recursive \
    --remote
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
  local status

  status="$(
    git diff \
      --name-only \
      --diff-filter="U" \
  )"

  local file
  file="$(echo "${status}" | fzf)"

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

function git-repo-rm-fzf {
  local repo
  repo="$(git-repo-ls | fzf)"

  rm -rf "${repo}"
}

function git-repo-cd-fzf {
  local repo
  repo="$(git-repo-ls | fzf)"

  cd "${repo}" || return 2
}

function __git_show_preview() {
  echo "$1" \
  | cut -d " " -f 1 \
  | git show \
    --stat \
    --oneline \
    --color="always" \
    "$(cat)"
}

export -f __git_show_preview

function git-show-fzf {
  # shellcheck disable=SC2016
  git log \
    --oneline \
    --color="always" \
    --decorate="short" \
    "$@" \
  | fzf \
    --ansi \
    --no-sort \
    --layout="reverse" \
    --preview-window="hidden" \
    --preview="__git_show_preview {}" \
    --bind="space:toggle-preview" \
  | cut -d ' ' -f 1 \
  | while read -r rev; do
      git diff \
        --color="always" \
        --unified=1 \
        "${rev}^..${rev}"
      break
    done
}

function git-cherry-pick-fzf() {
  git-log-oneline "$@" \
  | fzf \
    --multi \
    --reverse \
    --no-sort \
  | tac \
  | cut \
    -d $'\t' \
    -f 1 \
  | while read -r rev; do
      git cherry-pick "${rev}"
    done
}

function __git_show_preview_file() {
  echo "$1" \
  | cut -d $'\t' -f 1 \
  | git show \
    --color="always" \
    "$(cat)"
}

export -f __git_show_preview_file

function git-log-file-fzf() {
  local log

  log="$( \
    git-log-oneline \
      --all \
      -- "$@" \
  )"

  echo "${log}" | fzf \
    --ansi \
    --no-sort \
    --layout="reverse" \
    --preview="__git_show_preview_file {}"
}

function git-branch-rm-fzf() {
  local branches

  branches="$(git branch --format="%(refname:short)")"

  echo "${branches}" \
  | fzf --multi \
  | while read -r branch; do
      git branch -D "${branch}"
    done
}

function git-ssh-command-fzf() {
  local key_private_path

  key_private_path="$( \
    find ~/.ssh \
      -type f \
      -not -name "*.pub" \
      -and -not -name "config" \
      -and -not -name "authorized_keys" \
      -and -not -name "known_hosts*" \
    | while read -r path; do basename "${path}"; done \
    | fzf \
      --tac \
      --header="Pick SSH key" \
      --layout="reverse" \
      --no-sort \
      --height="33%" \
  )"

  export GIT_SSH_COMMAND="ssh -i ~/.ssh/${key_private_path}"
}

function git-diff-name-fzf() {
  local diff_names
  diff_names="$(git diff --cached --name-only)"

  echo "${diff_names}" \
  | fzf \
    --tac \
    --header="Choose changed file name" \
    --layout="reverse" \
    --no-sort \
    --height="25%"
}

function __git_diff_file_head() {
  local path
  path=$(echo "$1" | cut -d $'\t' -f 3)

  if [ -z "${path}" ]; then
    echo "No file selected"
    return
  fi

  git diff \
    --color \
    -- "${path}"
}

export -f __git_diff_file_head

function git-status-formatted() {
  git status --porcelain \
  | while IFS='' read -r line; do
      local status="${line:0:2}"
      local path="${line:3}"

      case "${status}" in
        "A ") echo -e "${COLOR_GREEN}STAGED${COLOR_CLEAR}\t${COLOR_GREEN}ADDED${COLOR_CLEAR}\t${path}" ;;
        "D ") echo -e "${COLOR_GREEN}STAGED${COLOR_CLEAR}\t${COLOR_RED}REMOVED${COLOR_CLEAR}\t${path}" ;;
        "M ") echo -e "${COLOR_GREEN}STAGED${COLOR_CLEAR}\t${COLOR_YELLOW}MODIFIED${COLOR_CLEAR}\t${path}" ;;
        " M") echo -e "${COLOR_YELLOW}UNSTAGED${COLOR_CLEAR}\t${COLOR_YELLOW}MODIFIED${COLOR_CLEAR}\t${path}" ;;
        " D") echo -e "${COLOR_YELLOW}UNSTAGED${COLOR_CLEAR}\t${COLOR_RED}REMOVED${COLOR_CLEAR}\t${path}" ;;
        " R") echo -e "${COLOR_YELLOW}UNSTAGED${COLOR_CLEAR}\t${COLOR_BLUE}MOVED${COLOR_CLEAR}\t${path}" ;;
        "??") echo -e "${COLOR_YELLOW}UNTRACKED${COLOR_CLEAR}\t${COLOR_GREEN}ADDED${COLOR_CLEAR}\t${path}" ;;
        "MM") echo -e "${COLOR_GREEN}PARTLY${COLOR_CLEAR}${COLOR_YELLOW}${COLOR_CLEAR}\t${COLOR_YELLOW}MODIFIED${COLOR_CLEAR}\t${path}" ;;
        *) ;;
      esac
  done \
  | sort
}

function git-stage-fzf-rich() {
  local command="$1"

  if [ -z "${command}" ]; then
    command="add"
  fi

  if [ "${command}" == "remove" ]; then
    command="restore --staged"
  fi

  local status
  status="$(git-status-formatted)"

  echo "${status}" \
  | fzf \
    -i \
    --multi \
    --no-sort \
    --tac \
    --ansi \
    --header="git ${command}" \
    --layout="reverse" \
    --preview-window="hidden" \
    --preview="__git_diff_file_head {}" \
    --bind="ctrl-d:toggle-preview" \
    --bind="ctrl-a:select-all" \
  | cut -d $'\t' -f 3 \
  | while read -r path; do
      echo "git ${command} ${path}"

      # shellcheck disable=SC2086
      git $command $path
    done
}

function docker-compose-logs() {
  docker-compose \
    "$@" \
    logs \
      --follow \
      --timestamps
}

function docker-compose-logs-pipe() {
  docker-compose \
    "$@" \
    logs \
      --follow \
      --timestamps \
    "$(cat)"
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

function python-path-base() {
  local python_path

  python_path="$(which python)"

  echo "warning: Not implemented Bash alias of Python for the current platform, falling back to system default path:" 1>&2
  echo "${python_path}" 1>&2
  echo 1>&2

  echo "${python_path}"
}

function python-path() {
  python-path-base
}

function venv-init() {
  "$(python-path)" -m venv .venv

  # shellcheck source=/dev/null
  source ".venv/bin/activate"

  pip install --upgrade pip

  local requirements="./requirements.txt"

  if [ -f "${requirements}" ]; then
    pip install -r "${requirements}"
  fi
}

function venv-create() {
  "$(python-path)" -m venv .venv
}

function venv-activate() {
  # shellcheck source=/dev/null
  source .venv/bin/activate
}

function venv-deactivate() {
  deactivate
}

function venv-reset() {
  deactivate || true
  rm -rf .venv
}

function pip-restore() {
  pip install \
    --require-virtualenv \
    -r requirements.txt
}

function pip-uninstall-all() {
  pip freeze \
  | xargs pip uninstall \
      --require-virtualenv \
      -y
}

function pip-uninstall-fzf() {
  pip freeze \
  | fzf \
  | pip uninstall "$(cat)" -y
}

function calc() {
  local command

  command='result = '
  command+="$@"
  command+='; print(result)'

  python3 -c "${command}"
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

function recall-fzf() {
  builtin history -a
  builtin history -c
  builtin history -r

  local entry

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

  if [ -z "${entry}" ]; then
    return 0
  fi

  read \
    -er \
    -i "${entry}" \
    -p "${PS1@P}" \
    input

  eval "${input}" && \
  builtin history -s "${input}"
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

function adb-colorize() {
  local app="$1"

  while read -r line; do
    if echo "${line}" | grep -q " I ${app}"; then
      echo -e "${COLOR_GREEN}${line}${COLOR_CLEAR}"
    elif echo "${line}" | grep -q " W ${app}"; then
      echo -e "${COLOR_YELLOW}${line}${COLOR_CLEAR}"
    elif echo "${line}" | grep -q " E ${app}"; then
      echo -e "${COLOR_RED}${line}${COLOR_CLEAR}"
    else
      echo -e "${COLOR_DIM}${line}${COLOR_CLEAR}"
    fi
  done
}

function adb-undebug() {
  adb shell am clear-debug-app
}

function android-sdkmanager-fzf() {
  local managers

  # TODO: Dehardcode Unity path.
  managers="$(find "/c/Program Files/Unity/Hub/Editor" -type f -path "*bin/sdkmanager.bat" 2>/dev/null)"

  if [ -z "${managers}" ]; then
    echo "No Android SDK managers found"
    return 1
  fi

  local manager

  manager="$(echo "${managers}" | fzf)"

  if [ -z "${manager}" ]; then
    echo "No Android SDK manager selected"
    return 1
  fi

  local packages

  packages="$( \
    "${manager}" --list 2>/dev/null \
    | grep '.*;.*|' \
    | tr -s " " \
    | cut -d '|' -f 1 \
    | sed -e 's/^[[:space:]]*//' \
  )"

  local package

  package="$(echo "${packages}" | fzf)"

  if [ -z "${package}" ]; then
    echo "No Android SDK package selected"
    return 1
  fi

  "${manager}" "${package}"

  echo "y" | "${manager}" --licenses
}

function inet-ip-ls() {
  ifconfig | awk '/inet / {print $2}'
}

function ip-local() {
  inet-ip-ls \
  | grep -v '127\.0\.0\.1' \
  | cut -d '/' -f 1
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

function gh-clone() {
  local repo

  repo="$(\
    gh repo list \
      --json "nameWithOwner" \
      --jq '.[] | .nameWithOwner' \
    | fzf \
  )"

  gh repo clone "${repo}"
}

function docker-hub-token-bearer-obtain() {
  if [ -z "${DOCKERHUB_USERNAME}" ]; then
    DOCKERHUB_USERNAME="$(cat | cut -d "@" -f 1)"
  fi

  local token_cache_tmp="/tmp/token-docker-hub-${DOCKERHUB_USERNAME}-$$"

  if [ -f "${token_cache_tmp}" ]; then
    cat "${token_cache_tmp}"
    return 0
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
  | jq -r '.token' \
  | tee "${token_cache_tmp}"
}

function docker-hub-repo-tag-ls() {
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

  local bearer_token
  bearer_token="$(docker-hub-token-bearer-obtain)"

  local response

  response="$( \
    curl \
      -s \
      -X "GET" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${bearer_token}" \
      "https://hub.docker.com/v2/namespaces/${namespace}/repositories/${repository}/tags" \
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

function docker-registry-token-bearer-obtain() {
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

  # TODO: Dehardcode.
  local scope="pull"
  local auth_host="auth.docker.io"
  local auth_service="registry.docker.io"

  local token_cache_tmp="/tmp/token-${auth_host}-${auth_service}-${namespace}-${repository}-${scope}-$$"

  if [ -f "${token_cache_tmp}" ]; then
    echo "debug: Got token from cache ${token_cache_tmp}" 1>&2
    cat "${token_cache_tmp}"
    return 0
  fi

  local url

  url+="https://"
  url+="${auth_host}"
  url+="/token?service="
  url+="${auth_service}"
  url+="&scope=repository:"
  url+="${namespace}/${repository}"
  url+=":${scope}"

  echo "warning: Got NEW token and put to cache ${token_cache_tmp}" 1>&2
  echo "warning: Handling this API is not stable and restricted to 100 requests per 6 hours for non-paid accounts" 1>&2

  curl -fsSL "${url}" \
  | jq -r '.token' \
  | tee "${token_cache_tmp}"
}

function docker-registry-repo-tag-ls() {
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

  local bearer_token
  bearer_token="$(docker-registry-token-bearer-obtain "${image}")"

  # TODO: Dehardcode.
  local registry_host="registry-1.docker.io"

  local response

  response="$( \
    curl \
      -s \
      -X "GET" \
      -H "HOST: ${registry_host}" \
      -H "Authorization: Bearer ${bearer_token}" \
      "https://${registry_host}/v2/${namespace}/${repository}/tags/list" \
  )"

  if [ "$(echo "${response}" | jq -r '.errors')" != "null" ]; then
    echo "${response}" 1>&2
    return 1
  fi

  echo "${response}" \
  | jq -r '.tags | reverse | .[]'
}

function docker-registry-repo-tag-aliases() {
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

  local bearer_token
  bearer_token="$(docker-registry-token-bearer-obtain "${image}")"

  # TODO: Dehardcode.
  local registry_host="registry-1.docker.io"

  docker-registry-repo-tag-ls "${image}" \
  | while read -r tag; do
      local header_tmp
      header_tmp="$(mktemp -q)"

      local body_tmp
      body_tmp="$(mktemp -q)"

      curl \
        -s \
        -X "GET" \
        -H "HOST: ${registry_host}" \
        -H "Authorization: Bearer ${bearer_token}" \
        -D "${header_tmp}" \
        -o "${body_tmp}" \
        "https://${registry_host}/v2/${namespace}/${repository}/manifests/${tag}"

      local errors

      errors="$( \
        cat "${body_tmp}" \
        | jq -r '. | .errors'
      )"

      if [ "${errors}" != "null" ]; then
        echo "${errors}" 1>&2
        return 1
      fi

      cat "${body_tmp}" \
      | jq -r '.tag' \
      | tr -d "\n"

      echo -en "\t"

      cat "${header_tmp}" \
      | grep -i "docker-content-digest" \
      | awk '{print $2}'

      rm -f "${header_tmp}"
      rm -f "${body_tmp}"
    done

  # TODO: Implement search. There is drafts:
  # digest_latest=$(while IFS=$'\t' read -r tag digest; do if [ "${tag}" == "latest" ]; then echo "${digest}"; fi; done)
  # while IFS=$'\t' read -r tag digest; do if [ "${digest}" == "${digest_latest}" ]; then echo "${tag}"; fi; done
}

function __docker_list_ancestors() {
  local parent_row="$1"

  local parent_id
  parent_id="$(echo "${parent_row}" | cut -d " " -f 1)"

  docker ps -a -f "ancestor=${parent_id}"
}

export -f __docker_list_ancestors

function docker-rmi-fzf() {
  local image_ids

  image_ids="$( \
    docker image ls --format="{{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}" \
    | column -t \
    | fzf \
      --multi \
      --preview='__docker_list_ancestors {}' \
      --bind="ctrl-a:select-all" \
    | cut \
      -d " " \
      -f 1 \
  )"

  echo "${image_ids}" \
  | while read -r image_id; do
      if [ -n "${image_id}" ]; then
        docker rmi --force "${image_id}"
      fi
    done
}

function docker-prune() {
  yes | docker system prune -a --force
}

function docker-stop-all() {
  docker stop "$(docker ps -q)"
}

function docker-kill-all() {
  docker kill "$(docker ps -q)"
}

function docker-rm-all() {
  docker rm "$(docker ps -a -q)"
}

function docker-rmi-all() {
  docker rmi -f "$(docker images -aq)"
}

function docker-container-fzf() {
  local container

  container="$( \
    docker ps "$@" \
    | tail -n +2 \
    | fzf \
      --multi \
      --preview='__docker_list_ancestors {}' \
      --bind="ctrl-a:select-all" \
    | cut \
      -d " " \
      -f 1 \
  )"

  echo "${container}"
}

function docker-logs-fzf() {
  local container
  container="$(docker-container-fzf)"

  docker logs \
    --follow \
    --timestamps \
    --details \
    "${container}"
}

function docker-stats-fzf() {
  local container
  container="$(docker-container-fzf)"

  docker stats "${container}"
}

function docker-stop-fzf() {
  local container
  container="$(docker-container-fzf)"

  docker stop "${container}"
}

function docker-exec-fzf() {
  local container
  container="$(docker-container-fzf)"

  docker exec -it "${container}" "$@"
}

function docker-kill-fzf() {
  local container
  container="$(docker-container-fzf)"

  docker kill "${container}"
}

function docker-restart-fzf() {
  local container
  container="$(docker-container-fzf -a)"

  docker restart "${container}"
}

function docker-rm-fzf() {
  local container
  container="$(docker-container-fzf -f "status=exited")"

  docker rm "${container}"
}

function rm-fzf() {
  find . -maxdepth 1 -type f \
  | sort \
  | fzf --multi \
  | while read -r path; do
      rm -f "${path}"
    done
}

function rmdir-fzf() {
  find . -maxdepth 1 -type d \
  | sort \
  | fzf --multi \
  | while read -r path; do
      rm -rf "${path}"
    done
}

function cd-fzf() {
  local dir

  dir="$( \
    find . -maxdepth 1 -type d \
    | concat ".." \
    | sort \
    | fzf \
  )"

  cd "${dir}" || return 2
}

function foreach-fzf() {
  find . -maxdepth 1 -type f \
  | sort \
  | fzf --multi \
  | while read -r path; do
      "$@" "${path}"
    done
}

function npm-local-path() {
  pwd
}

function npm-local-format() {
  local package
  package="$(pwd)/package.json"

  if [ ! -f "${package}" ]; then
    echo "error: There is no NPM package in CWD"
    return 1
  fi

  local package_name
  package_name="$(jq -r '.name' < "${package}")"

  local package_path_absolute
  package_path_absolute="file:$(npm-local-path)"

  echo "\"${package_name}\": \"${package_path_absolute}\","
}

# shellcheck disable=SC2129
# shellcheck disable=SC2016
function path-edit-fzf() {
  local path_before="${PATH}"

  local tmp
  tmp="$(mktemp)"

  echo "${PATH}" \
  | tr ":" "\n" \
  | uniq-unsorted \
  > "${tmp}"

  local chosen_editor

  chosen_editor="$( \
    ( \
      echo "nano"; \
      echo "code"; \
      echo "vi"; \
    ) \
    | fzf \
        --header="Choose editor:" \
        --layout="reverse" \
        --no-sort \
        --height="25%" \
  )"

  if [ "${chosen_editor}" == "code" ]; then
    code --new-window --wait "${tmp}"
  elif [ "${chosen_editor}" == "nano" ]; then
    nano "${tmp}"
  elif [ "${chosen_editor}" == "vi" ]; then
    vi "${tmp}"
  elif [ -z "${chosen_editor}" ]; then
    return 0
  else
    echo "Not supported editor chosen: ${chosen_editor}" 1>&2
    return 1
  fi

  PATH="$(echo -n "$(cat "${tmp}")" | tr "\n" ":")"
  export PATH

  rm -f "${tmp}"

  # My personal choice to store the PATH:
  local target_file="${BASH_PATH_FILE}"

  echo '#!/bin/bash' > "${target_file}"
  echo >> "${target_file}"

  local is_first_path_assigned=false

  echo "${PATH}" \
  | while read -d ":" -r dir; do
      if [ ! -d "${dir}" ]; then
        continue
      fi

      local dir_subst="${dir/${HOME}/'${HOME}'}"

      echo -n 'export PATH="' >> "${target_file}"
      echo -n "${dir_subst}" >> "${target_file}"

      if $is_first_path_assigned; then
        echo -n ':${PATH}' >> "${target_file}"
      else
        is_first_path_assigned=true
      fi
      echo '"' >> "${target_file}"
    done

  echo
  echo "PATH modified:"
  echo
  diff \
    --side-by-side \
    --color="always"  \
    <(echo "${path_before}" | tr ":" "\n" | sort --uniq) \
    <(echo "${PATH}" | tr ":" "\n" | sort --uniq)
  echo
}

function path-append() {
  local dir="$1"

  local target_file="${BASH_PATH_FILE}"

  if [ -d "$1" ]; then
    PATH="${PATH}:${dir}"
    echo "PATH=\"${PATH}\"" > "${target_file}"
  else
    echo "Directory \"${dir}\" does not exist" 1>&2
  fi
}

function ipinfo() {
  local ip="$1"

  local address=""

  if [ -n "${ip}" ]; then
    address="${ip}/"
  fi

  local query=""

  if [ -n "${IPINFO_TOKEN}" ]; then
    query="?token=${IPINFO_TOKEN}"
  fi

  curl "https://ipinfo.io/${address}json${query}"
  echo
}

function resolve() {
  local domain="$1"
  dig +short "${domain}" \
  | grep -E '^[0-9\.]+$|^([0-9a-fA-F:]+:+)+[0-9a-fA-F]+$'
}

function ipinfo-resolve() {
  local domain="$1"

  resolve "${domain}" \
  | while read -r ip; do
      ipinfo "${ip}";
    done
}

function rg-fzf() {
  local results
  results="$(rg "$1" --files-without-match)"

  echo "${results}" \
  | sort --uniq \
  | fzf
}

function find-fzf() {
  local results
  results="$(find "$@")"

  echo "${results}" \
  | sort --uniq \
  | fzf
}

function code-new() {
  touch "$1"
  code "$1" --reuse-window
}

function openvpn-conf-dir() {
  echo "/etc/openvpn"
}

function openvpn-profile-fzf() {
  rm -f "$(openvpn-conf-dir)/client.conf"

  # shellcheck disable=SC2012
  find "$(openvpn-conf-dir)" \
    -name "*.ovpn" \
    -or -name "*.conf" \
  | fzf \
  | cp "$(cat)" "$(openvpn-conf-dir)/client.conf"
}

function openvpn-connect() {
  sudo killall openvpn 2>/dev/null

  echo -e "${COLOR_BLUE}Attempt to connect...${COLOR_CLEAR}"
  echo

  sudo nohup openvpn "$(openvpn-conf-dir)/client.conf" > /dev/null 2>&1 &

  sleep 4

  echo "Retreiving current IP info..."
  echo

  echo -en "${COLOR_GREEN}"

  # Obtain token at https://ipinfo.io/
  curl "https://ipinfo.io/?token=${IPINFO_TOKEN}" \
    --max-time 3 \
    --fail

  exit_code=$?

  echo -en "${COLOR_CLEAR}"

  echo

  if [ $exit_code -eq 1 ]; then
    echo -e "${COLOR_GREEN}Connected${COLOR_CLEAR}"
  else
    echo -e "${COLOR_RED}Failed to connect${COLOR_CLEAR}" 1>&2
  fi

  echo

  return $exit_code
}

function openvpn-disconnect() {
  sudo killall openvpn > /dev/null 2>&1

  sleep 4

  echo -e "${COLOR_YELLOW}Disconnected${COLOR_CLEAR}"
  echo

  echo "Retreiving current IP info..."
  echo

  echo -en "${COLOR_YELLOW}"

  # Obtain token at https://ipinfo.io/
  curl "https://ipinfo.io/?token=${IPINFO_TOKEN}" \
    --max-time 3 \
    --fail

  exit_code=$?

  echo -en "${COLOR_CLEAR}"

  echo
  echo

  return $exit_code
}

function openvpn-reconnect() {
  echo "Reconnecting..."
  echo

  exit_code=1

  while [ $exit_code -ne 0 ]; do
    openvpn-disconnect
    openvpn-connect

    exit_code=$?
  done
}

function doctl-ssh-fzf() {
  doctl compute ssh "$( \
    doctl compute droplet list \
      --format="ID,Name,PublicIPv4,Region,Image" \
      --no-header \
    | fzf \
    | tr -s " " \
    | cut -d " " -f 1 \
  )"
}

function doctl-update-hosts() {
  local droplet_ips

  droplet_ips="$( \
    doctl compute droplet list \
      --format="PublicIPv4,Name" \
      --no-header \
    | tr -s " " \
  )"

  local clear_from
  clear_from="$(sudo grep -n "DigitalOcean.*begin" /etc/hosts | cut -d ":" -f 1)"

  local clear_to
  clear_to="$(sudo grep -n "DigitalOcean.*end" /etc/hosts | cut -d ":" -f 1)"

  if [ -n "${clear_from}" ] && [ -n "${clear_to}" ]; then
    sudo sed -i "${clear_from},${clear_to}d" /etc/hosts
  fi

  sudo "${SHELL}" -c "echo \"# ===== DigitalOcean Droplets (begin) =====\" >> /etc/hosts"

  for droplet_ip in ${droplet_ips}; do
    sudo "${SHELL}" -c "echo \"${droplet_ip}\" >> /etc/hosts"
  done

  sudo "${SHELL}" -c "echo \"# ===== DigitalOcean Droplets (end) =====\" >> /etc/hosts"
}

function curl-ping() {
  curl -o /dev/null -sL -w '%{time_connect}s\n' "$1"
}

function ssh-fzf() {
  local host

  host="$( \
    grep -o "^Host .*$" ~/.ssh/config \
    | cut \
      -d " " \
      -f 2 \
    | fzf \
      --tac \
      --header="Pick SSH host:" \
      --layout="reverse" \
      --no-sort \
      --height="33%" \
  )"

  if [ -z "${host}" ]; then
    return 0
  fi

  read \
    -er \
    -i "ssh ${host}" \
    -p "${PS1@P}" \
    input

  eval "${input}"
}

function unity-upm-add-local() {
  local package_path

  package_path="$( \
    find ~ \
      -name "package.json" \
      -maxdepth 2 \
    2>/dev/null \
    | fzf \
      --tac \
      --header="Pick UPM package:" \
      --layout="reverse" \
      --no-sort \
      --height="33%" \
  )"

  "${BASH_ALIAS_SYNC_REPO}/python-scripts/unity-upm-add-local.py" "${package_path}"
}

function mv-ln() {
  local source_path="$1"
  local target_path="$2"

  local source_path_real
  source_path_real="$(realpath "${source_path}")"

  local target_path_dirname_real
  local target_path_basename

  if [ -d "${target_path}" ]; then
    target_path_dirname_real="$(realpath "${target_path}")"
    target_path_basename="$(basename "${source_path}")"
  else
    target_path_dirname_real="$(realpath "$(dirname "${target_path}")")"
    target_path_basename="$(basename "${target_path}")"
  fi

  local target_path_real
  target_path_real="${target_path_dirname_real}/${target_path_basename}"

  mv "${source_path_real}" "${target_path_real}"
  ln -s "${target_path_real}" "${source_path_real}"

  echo "'${source_path_real}' -> '${target_path_real}'" 1>&2
}

function ln-unlink() {
  local target_path="$1"

  if [ ! -L "${target_path}" ]; then
    echo "error: The provided path is not a symlink" 1>&2
    return 1
  fi

  local destination_path
  destination_path="$(readlink -- "${target_path}")"

  unlink -- "${target_path}"
  mv "${destination_path}" "${target_path}"

  echo "Unlinked and moved '${target_path}' from '${destination_path}'" 1>&2
}

function curl-format-download() {
  local url="$1"

  echo "curl -O \"${url}\""
}

# shellcheck disable=SC2120
function nmap-local-ls() {
  local ip_masks="$1"

  if [ -z "${ip_mask}" ]; then
    ip_masks="$( \
      ip-local \
      | while read -r ip; do
          echo "${ip}/24"
        done \
    )"
  fi

  echo "${ip_masks}" \
  | while read -r ip_mask; do
      echo "${ip_mask}" \
      | nmap -sn "${ip_mask}" -oG - \
      | grep "Status: Up" \
      | cut -d ' ' -f 2
    done
}

function ssh-fzf-nmap-local() {
  local host

  host="$( \
    nmap-local-ls \
    | fzf \
      --tac \
      --header="Pick SSH host:" \
      --layout="reverse" \
      --no-sort \
      --height="33%" \
  )"

  if [ -z "${host}" ]; then
    return 0
  fi

  read \
    -er \
    -i "ssh ${host}" \
    -p "${PS1@P}" \
    input

  eval "${input}"
}

function ssh-id-fzf() {
  pushd ~/.ssh > /dev/null || return 2

  local private_key_path

  private_key_path="$( \
    find . -type f \
    | while read -r file; do
        if grep -iq "private" "${file}"; then
          echo "${file}"
        fi
      done \
    | fzf \
        --tac \
        --header="Pick SSH key which will be \`id_rsa\`:" \
        --layout="reverse" \
        --no-sort \
        --height="33%" \
  )"

  cp -f "${private_key_path}" "./id_rsa"
  cp -f "${private_key_path}.pub" "./id_rsa.pub"

  popd > /dev/null || return 2
}

function ps-port() {
  local port="$1"
  sudo lsof -i :$port
}
