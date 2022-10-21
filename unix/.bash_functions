#!/bin/bash

function rg-fzf() {
  results="$(rg "$1" --files-without-match)"
  echo "${results}" | sort --uniq | fzf
}

function find-fzf() {
  results="$(find "$@")"
  echo "${results}" | sort --uniq | fzf
}
