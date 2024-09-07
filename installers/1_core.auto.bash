#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install $(< "${script_dir}/1_brew.packages")
  # TODO: hack for now because bitwarden versions are weird
  brew link --overwrite node@14
  npm install -g npm@7 --force

else
  sudo apt-get -y update
  sudo apt-get -y upgrade

  sudo apt -y install $(< "${script_dir}/1_core.packages")
fi
