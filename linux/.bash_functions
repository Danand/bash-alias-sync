#!/bin/bash

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

function openvpn-profile() {
  rm -f "/etc/openvpn/client.conf"

  # shellcheck disable=SC2012
  find "/etc/openvpn" \
    -name "*.ovpn" \
    -or -name "*.conf" \
  | fzf \
  | cp "$(cat)" "/etc/openvpn/client.conf"
}

function openvpn-connect() {
  sudo killall openvpn 2>/dev/null

  sudo openvpn "/etc/openvpn/client.conf" &

  sleep 5

  echo "Connected"
  echo

  echo "Current IP info:"

  # Obtain token at https://ipinfo.io/
  curl "https://ipinfo.io/?token=${IPINFO_TOKEN}"
  echo
}

function openvpn-disconnect() {
  sudo killall openvpn

  sleep 5

  echo "Disconnected"
  echo

  echo "Current IP info:"

  # Obtain token at https://ipinfo.io/
  curl "https://ipinfo.io/?token=${IPINFO_TOKEN}"
  echo
}

function ipinfo() {
  curl "https://ipinfo.io/?token=${IPINFO_TOKEN}"
  echo
}

function doctl-ssh() {
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

# shellcheck disable=SC2129
# shellcheck disable=SC2016
function path-edit() {
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
  local target_file="${HOME}/.bash_path"

  echo '#!/bin/bash' > "${target_file}"
  echo >> "${target_file}"
  echo 'unset PATH' >> "${target_file}"
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
