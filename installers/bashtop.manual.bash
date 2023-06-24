#!/usr/bin/env bash
# shellcheck disable=SC1091
source '_core.bash'

if [[ "$(uname -s)" == "Darwin" ]]; then
  true
else
  sudo add-apt-repository --yes ppa:bashtop-monitor/bashtop
  sudo apt-get --yes update
  sudo apt-get --yes install bashtop
fi
