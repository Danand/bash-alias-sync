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

  docker run -it "${image_name}" $@
}
