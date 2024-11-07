#!/bin/bash

function git-chmod() {
  git config core.fileMode true

  local mod="$1"

  local paths
  paths="$(ls -1a "$2")"

  IFS=$'\n'
  for path in ${paths}; do
    chmod "${mod}" "${path}"
    git update-index --chmod="${mod}" "${path}" > /dev/null 2>&1 \
    || git add --chmod="${mod}" "${path}" > /dev/null 2>&1
  done
  unset IFS
}

function git-branch-first-commit() {
  local branch
  branch="$(git branch --show-current)"

  local last_commit="HEAD"

  for commit in $(git log "${branch}" --oneline --format=%H); do
    if [ "$(git branch --contains "${commit}" | wc -l)" -gt 1 ]; then
      echo "${last_commit}"
      return 0
    fi

    last_commit="${commit}"
  done
}

function git-reset-branches() {
  git branch --format "%(refname:short)" --quiet 2>/dev/null | while read -r branch; do
    if [ "${branch}" != "$(git branch --show-current)" ]; then
      git branch -D "${branch}" 2>/dev/null
    fi
  done

  git submodule foreach "${SHELL} -c ${FUNCNAME[0]}"
}

function git-bump() {
  tag_latest="$(git describe --tags --abbrev=0)"

	patch_old="$(echo "${tag_latest}" | awk -F '.' '{ print $NF }')"
	patch_new="$(( patch_old + 1 ))"
	major_minor="$(echo "${tag_latest}" | awk -F '.' '{ print $1"."$2 }')"

	tag_new="${major_minor}.${patch_new}"

	git tag "${tag_new}"

  echo "Tagged ${tag_new} ($(git rev-parse --short HEAD)), previous tag was ${tag_latest} ($(git rev-parse --short "${tag_latest}"))" 1>&2
}

function git-repo-ls {
  find \
    . \
    -maxdepth 2 \
    -type d \
    -name ".git" \
  | while read -r git_dir; do
      dirname "${git_dir}"
    done
}

function git-patch-scp() {
  local repo_path="$1"

  local patch
  patch="$(git diff --patch HEAD)"

  # shellcheck disable=SC2029
  ssh "${@:2}" -- "cd \"${repo_path}\" && echo '${patch}' | git apply"
}

function git-log-oneline {
  git log \
    --format=$'%h\t%ad\t%aN\t%s' \
    --date="iso-strict" \
    "$@"
}

function git-log-last-message() {
  git log -1 --format='%s'
}

function git-branch-push-copy() {
  local branch="$1"

  git branch "${branch}"
  git push origin "${branch}:${branch}"
}

function git-patch-merge() {
  local rev="$1"

  git diff \
    "${rev}^1" \
    "${rev}" \
    --full-index \
    --binary
}

function git-branch-head() {
  local rev="$1"

  git rev-parse "${rev}^2"
}

function git-branch-head-merge() {
  local rev="$1"
  local branch_other="$2"

  local branch_current
  branch_current="$(git branch --show-current)"

  local branch_other_head
  branch_other_head="$(git-branch-head "${rev}")"

  if [ -z "${branch_other}" ]; then
    branch_other="${branch_other_head}"
  fi

  git merge \
    --no-ff \
    --message "Merge branch '${branch_other}' into '${branch_current}'" \
    "${branch_other_head}"
}

function git-branch-mv() {
  local branch_other="$1"

  if [ -n "${branch_other}" ]; then
    read \
      -er \
      -i "${branch_other}" \
      -p "${PS1@P}" \
      branch_name_new

    git branch -m "${branch_other}" "${branch_name_new}"
  else
    read \
      -er \
      -i "$(git branch --show-current)" \
      -p "${PS1@P}" \
      branch_name_new

    git branch -M "${branch_name_new}"
  fi
}

function git-branch-mv-fzf() {
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

  git-branch-mv "${selected_branch}"
}

function measure() {
  time "${@}"
  echo 1>&2
  echo "Time elapsed for \`${*}\`" 1>&2
}

function history-trim() {
  if [ -z "$1" ]; then
    echo "usage: history-trim <amount>" 1>&2
    return 1
  fi

  builtin history -c
  builtin history -r

  builtin history \
  | tail -n "$1" \
  | sed -e 's/^[ ]*[0-9]\+[ ]*//' \
  > "${HOME}/.bash_history"
}

function remember() {
  local cache_dir_root="/tmp/cache-remember"
  local cache_dir="${cache_dir_root}/$$"

  if [ "$1" == "--forget" ]; then
    rm -rf "${cache_dir}"
    shift
  fi

  if [ "$1" == "--clear" ]; then
    rm -rf "${cache_dir_root}"
    shift
  fi

  if [ $# -eq 0 ]; then
    return 0
  fi

  mkdir -p "${cache_dir}"

  local hash_data="${*}"

  git rev-parse HEAD > /dev/null 2>&1 || eval is_in_repo=$? && true

  # shellcheck disable=SC2154
  if [ "${is_in_repo}" == "0" ]; then
    hash_data+="$(git rev-parse HEAD)"
    hash_data+="$(git diff HEAD --name-only)"
  else
    hash_data+="$(date +%Y-%m-%d-%H)"
    hash_data+="$(pwd)"
  fi

  local hash_array

  # shellcheck disable=SC2207
  hash_array=($(echo "${hash_data}" | md5sum))

  local cache_key

  # shellcheck disable=SC2116
  # shellcheck disable=SC2128
  cache_key="$(echo "${hash_array}")"

  local cache_file
  cache_file="${cache_dir}/${cache_key}"

  if [ -f "${cache_file}" ]; then
    cat "${cache_file}"
  else
    stdbuf --output=L "${@}" | tee "${cache_file}"
  fi
}

function prompt-apply-mingw-like-without-git() {
  PS1='\n\[\033[1m\]\[\033[32m\]`whoami`\[\033[0m\]@\[\033[34m\]`uname -n`\[\033[0m\]:`pwd`\[\033[36m\]\[\033[0m\]\[\033[0m\]\n$ '
}

function prompt-apply-mingw-like() {
  PS1='\n\[\033[1m\]\[\033[32m\]`whoami`\[\033[0m\]@\[\033[34m\]`uname -n`\[\033[0m\]:`pwd`\[\033[36m\]`__git_ps1`\[\033[0m\]\[\033[0m\]\n$ '
}

function prompt-apply-with-date() {
  PS1='\n\[\033[1m\]\[\033[32m\]`whoami`\[\033[0m\]@\[\033[34m\]`uname -n`\[\033[0m\]:`pwd` \[\033[0;34m\]`date +"%Y-%m-%d %H-%M-%S"`\[\033[0m\] \$ '
}

function grep-errors() {
  cat | grep \
    -ie "warn" \
    -ie "err" \
    -ie "issue" \
    -ie "fail" \
    -ie "disable" \
    -ie "unable" \
    -ie "stop" \
    -ie "interrupt" \
    -ie "miss" \
    -ie "problem" \
    -ie "fault" \
    -ie "bug" \
    -ie "crash" \
    -ie "flaw" \
    -ie "incompat" \
    -ie "mismatch" \
    -ie "break" \
    -ie "broken" \
    -ie "corrupt" \
    -ie "exception" \
    -ie "abrupt" \
    -ie "ineffective" \
    -ie "malfunction" \
    -ie "mistake" \
    -ie "defect"
}

function npm-install-recursive() {
  find \
    . -type f \
    -name "package.json" \
    -and -not -path "*node_modules*" \
  | while read -r package_path; do
      local package_dir
      package_dir="$(dirname "${package_path}")"

      echo
      echo "Running \`npm install\` at \`${package_dir}\`:"

      ( \
        cd "${package_dir}" \
        && npm install \
      )

    done
}

function touch-p() {
  local path="$1"

  local dir
  dir="$(dirname "${path}")"

  mkdir -p "${dir}"

  touch "${path}"

  echo "${path}"
}

function concat() {
  cat

  while [ ! $# -eq 0 ]; do
    echo "$1"
    shift
  done
}

function gh-merge-fork-branch() {
  local fork_branch="$1"

  local remote
  remote="$(echo "${fork_branch}" | cut -d ":" -f 1)"

  local branch
  branch="$(echo "${fork_branch}" | cut -d ":" -f 2)"

  local repo_name
  repo_name="$(git remote get-url origin | cut -d "/" -f 2)"

  git remote add "${remote}" "git@github.com:${remote}/${repo_name}" 2>/dev/null || true
  git fetch "${remote}" "${branch}"

  git merge --no-ff "${remote}/${branch}"
}
