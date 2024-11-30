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

function __systemd_status_preview() {
  local services="$1"

  export SYSTEMD_COLORS=1

  echo -n "${services}" \
  | tr ' ' '\n' \
  | while read -r service; do
      systemctl status "${service}"
      echo
    done
}

export -f __systemd_status_preview

function systemd-fzf() {
    local preview_window="right:67%"

    local services

    services="$( \
      systemctl list-unit-files \
        --type=service \
        --no-pager \
        --all \
        --plain \
        --no-legend \
      | cut -d ' ' -f 1 \
      | grep -v "@" \
      | uniq \
      | fzf \
        -i \
        --header="Choose services:" \
        --layout="reverse" \
        --no-sort \
        --multi \
        --ansi \
        --preview="__systemd_status_preview {}" \
        --preview-window="${preview_window}" \
    )"

    if [ -z "${services}" ]; then
      return 0
    fi

    local services_args
    services_args="$(echo ${services} | tr '\n' ' ')"

    local command

    command="$( \
      ( \
        echo "restart"
        echo "stop"
        echo "disable"
        echo "enable"
      ) \
      | fzf \
        -i \
        --header="Choose command:" \
        --layout="reverse" \
        --no-sort \
        --ansi \
        --preview="__systemd_status_preview \"${services_args}\"" \
        --preview-window="${preview_window}" \
    )"

    if [ -z "${command}" ]; then
      return 0
    fi

    echo "${services}" \
    | while read -r service; do
        sudo systemctl "${command}" "${service}"
        systemctl status "${service}"
        echo
      done
}
