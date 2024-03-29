#!/bin/bash

# shellcheck source=/dev/null
# shellcheck disable=SC2129

git clean -fdx "**/.bash_deps.lock"

if [ -f "${HOME}/.bash_aliases" ]; then
  profile_path="${HOME}/.bash_aliases"
elif [ -f "${HOME}/.bashrc" ]; then
  profile_path="${HOME}/.bashrc"
else
  profile_path="${HOME}/.bash_profile"
fi

repo_dir=$(realpath -- "$(dirname -- "$0")")

echo >> "${profile_path}"
echo -n "export BASH_ALIAS_SYNC_REPO='" >> "${profile_path}"
echo -n "${repo_dir}" >> "${profile_path}"
echo "'" >> "${profile_path}"

# shellcheck disable=SC2016
echo 'source "${BASH_ALIAS_SYNC_REPO}/.bash_aliases"' >> "${profile_path}"

source "${profile_path}"
