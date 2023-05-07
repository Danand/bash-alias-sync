#!/bin/bash

function rg-fzf() {
  results="$(rg "$1" --files-without-match)"
  echo "${results}" | sort --uniq | fzf
}

function find-fzf() {
  results="$(find "$@")"
  echo "${results}" | sort --uniq | fzf
}

function code-new() {
  touch "$1"
  code "$1" --reuse-window
}

function docker-run-it() {
  selected_image_line="$(docker image ls | tail -n +2 | fzf | tr -s ' ')"

  image_name="$(echo "${selected_image_line}" | cut -d ' ' -f 1)"
  image_name+=":"
  image_name+="$(echo "${selected_image_line}" | cut -d ' ' -f 2)"

  docker run -it "${image_name}" "$@"
}

function openvpn-profile() {
  rm -f "/etc/openvpn/client.conf"
  ls -1 /etc/openvpn/*.conf | fzf | cp "$(cat)" "/etc/openvpn/client.conf"
}

function openvpn-connect() {
  sudo openvpn /etc/openvpn/client.conf &

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
  doctl compute ssh \
  "$(doctl compute droplet list \
    --format="ID,Name,PublicIPv4,Region,Image" \
    --no-header | \
    fzf | \
    tr -s " " | \
    cut -d " " -f 1)"
}

function doctl-update-hosts() {
  droplet_ips="$(doctl compute droplet list \
    --format="PublicIPv4,Name" \
    --no-header | \
    tr -s " ")"

  clear_from="$(sudo grep -n "DigitalOcean.*begin" /etc/hosts | cut -d ":" -f 1)"
  clear_to="$(sudo grep -n "DigitalOcean.*end" /etc/hosts | cut -d ":" -f 1)"

  if [ -n "${clear_from}" ] && [ -n "${clear_to}" ]; then
    sudo sed -i "${clear_from},${clear_to}d" /etc/hosts
  fi

  sudo bash -c "echo \"# ===== DigitalOcean Droplets (begin) =====\" >> /etc/hosts"

  for droplet_ip in ${droplet_ips}; do
    sudo bash -c "echo \"${droplet_ip}\" >> /etc/hosts"
  done

  sudo bash -c "echo \"# ===== DigitalOcean Droplets (end) =====\" >> /etc/hosts"
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
