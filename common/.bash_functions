#!/bin/bash

# TODO: fix.
function path-edit() {
  local tmp
  tmp="$(mktemp)"

  echo "${PATH}" | tr ":" "\n" > "${tmp}"
  code --new-window --wait "${tmp}"

  PATH="$(tr "\n" ":" < "${tmp}")"
  export PATH

  readarray -t paths < "${tmp}"

  target_file="${HOME}/.bash_path"

  if [ ! -f "${target_file}" ]; then
    target_file="${HOME}/.bashrc"
  fi

  content="$(grep -v -E ".*export PATH=.*" "${target_file}")"

  echo "${content}" > "${target_file}"

  for path in ${paths[@]}; do
    echo -n 'export PATH="' >> target_file
    echo -n "${path}"
    echo -n ':$PATH"'
  done

  rm -f "${tmp}"
}

function git-chmod() {
  file_mode_enabled="$(git config --get core.fileMode)"
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

  if [ -z "${file_mode_enabled}" ]; then
    git config --unset core.fileMode
  else
    git config core.fileMode "${file_mode_enabled}"
  fi
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
	patch_new="$(( $patch_old + 1 ))"
	major_minor="$(echo "${tag_latest}" | awk -F '.' '{ print $1"."$2 }')"

	tag_new="${major_minor}.${patch_new}"

	git tag "${tag_new}"

  echo "Tagged ${tag_new} ($(git rev-parse --short HEAD)), previous tag was ${tag_latest} ($(git rev-parse --short "${tag_latest}"))" 1>&2
}

function git-repo-ls {
  find . -maxdepth 2 -type d -name ".git" -print0 | xargs -0 -I git_dir $SHELL -c 'dirname git_dir'
}

function git-repo-rm-fzf {
  git-repo-ls | fzf | rm -rf $(cat)
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
  cache_dir_root="/tmp/cache-remember"
  cache_dir="${cache_dir_root}/$$"

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

  hash_data="${*}"

  git rev-parse HEAD > /dev/null 2>&1 || eval is_in_repo=$? && true

  # shellcheck disable=SC2154
  if [ "${is_in_repo}" == "0" ]; then
    hash_data+="$(git rev-parse HEAD)"
    hash_data+="$(git diff HEAD --name-only)"
  else
    hash_data+="$(date +%Y-%m-%d-%H)"
    hash_data+="$(pwd)"
  fi

  # shellcheck disable=SC2207
  hash_array=($(echo "${hash_data}" | md5sum))

  # shellcheck disable=SC2116
  # shellcheck disable=SC2128
  cache_key="$(echo "${hash_array}")"

  cache_file="${cache_dir}/${cache_key}"

  if [ -f "${cache_file}" ]; then
    cat "${cache_file}"
  else
    stdbuf --output=L "${@}" | tee "${cache_file}"
  fi
}

function where() {
  local condition

  if [ $# -eq 1 ]; then
    condition="$1"
  else
    echo "Invalid number of arguments" 1>&2
    return 1;
  fi

  column_index="$(echo "${condition}" | grep -Po "%(\K\d*)")"

  while read -r row; do
    # shellcheck disable=SC2086
    value=$(echo "${row}" | cut -d $'\t' -f $column_index)

    subst_condition="${condition/"%$column_index"/$value}"

    # shellcheck disable=SC1072,SC1073,SC1009
    if [ $subst_condition ]; then
      echo "${row}"
    fi
  done
}

function prompt-apply-mingw-like() {
  PS1='\n\033[32m`whoami`\033[0m@\033[34m`uname -n`\033[0m:`pwd`\033[36m`__git_ps1`\033[0m\n$ '
}
