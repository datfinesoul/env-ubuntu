#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install $(< "${script_dir}/1_brew.packages")
else
  sudo apt-get -y update
  sudo apt-get -y upgrade

  sudo apt -y install $(< "${script_dir}/1_core.packages")
fi
