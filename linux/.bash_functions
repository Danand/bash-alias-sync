#!/bin/bash

function detect-package-manager() {
  declare -A dist_release

  dist_release["/etc/redhat-release"]="yum"
  dist_release["/etc/arch-release"]="pacman"
  dist_release["/etc/gentoo-release"]="emerge"
  dist_release["/etc/SuSE-release"]="zypp"
  dist_release["/etc/debian_version"]="apt"
  dist_release["/etc/alpine-release"]="apk"

  for key in "${!dist_release[@]}"; do
    if [ -f "${key}" ]; then
      echo "${dist_release["${key}"]}"
      return 0
    fi
  done

  1>&2 echo "Cannot detect package manager on system $(uname -o) $(uname -r)"

  return 2
}

function port-ls-busy() {
  sudo netstat -lnp \
  | grep "LISTEN" \
  | awk '{print $4}' \
  | awk -F ":" '{print $NF}' \
  | sort -n \
  | uniq -c \
  | awk '{if ($1 != 1) print $2}'
}

# shellcheck disable=SC2046
# shellcheck disable=SC2003
function next() {
  wmctrl -n $(expr $(wmctrl -d | wc -l) + 1)
  wmctrl -s $(expr $(wmctrl -d | grep "\*" | cut -d " " -f 1) + 1)
  "$@"
}

function apport-enable() {
  sudo $SHELL -c 'echo "enabled=1" > "/etc/default/apport"'
  sudo service apport restart
}

function apport-clear() {
  find \
    "/var/crash" \
    -type f \
    -name "*.crash" \
    -print0 \
  | xargs \
    -0 \
    -I path \
    $SHELL \
      -c \
      'sudo rm -f "path"'
}

function apport-unpack-fzf() {
  unpack_dir="$(\
    mktemp \
      --quiet \
      --directory \
      --dry-run \
  )"

  crash_dump="$(\
    find \
      "/var/crash" \
      -type f \
      -name "*.crash" \
    | fzf \
  )"

  if [ -z "${crash_dump}" ]; then
    return 0;
  fi

  echo "Unpacking..." 1>&2

  apport-unpack \
    "${crash_dump}" \
    "${unpack_dir}"

  echo "Requesting backtrace..." 1>&2

  gdb_commands="$(\
    mktemp \
      --quiet \
      --dry-run \
  )"

  echo "backtrace" > "${gdb_commands}"
  echo "exit" >> "${gdb_commands}"

  (
    cd "${unpack_dir}" && \
    gdb \
      "$(cat "ExecutablePath")" \
      --command="${gdb_commands}" \
      "CoreDump"
  )

  rm -rf "${unpack_dir}"
  rm -f "${gdb_commands}"
}
