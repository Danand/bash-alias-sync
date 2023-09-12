#!/bin/bash

function npm-local-path() {
  local volume_label
  volume_label="$(pwd | cut -d "/" -f 2)"

  local remaining_path
  remaining_path="$(pwd | cut -d "/" -f 3-)"

  echo "${volume_label}:/${remaining_path}"
}
