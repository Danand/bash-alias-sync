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

  image_name="$(echo $selected_image_line | cut -d ' ' -f 1)"
  image_name+=":"
  image_name+="$(echo $selected_image_line | cut -d ' ' -f 2)"

  docker run -it "${image_name}" "$@"
}

function openvpn-connect() {
  sudo openvpn --config "/etc/openvpn/client.conf"
}

function doctl-ssh() {
  doctl compute ssh "$(doctl compute droplet list --format=ID,Name,PublicIPv4,Region,Image --no-header | fzf | cut -d $'\t' -f 1)"
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
    else
      1>&2 echo "Cannot detect package manager on system $(uname -o) $(uname -r)"
    fi
  done
}
