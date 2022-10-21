#!/bin/bash

if [ -f "$HOME/.bash_profile" ]; then
  profile_path="$HOME/.bash_profile"
else
  profile_path="$HOME/.bash_aliases"
fi

repo_dir=$(realpath -- "$(dirname -- "$0")")

echo "" >> "${profile_path}"
echo "export BASH_ALIAS_SYNC_REPO='${repo_dir}'" >> "${profile_path}"
echo 'source "$BASH_ALIAS_SYNC_REPO/.bash_aliases"' >> "${profile_path}"

source "${profile_path}"
