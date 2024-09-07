#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

node --version
# Setting up snap (snap.d) inside a docker container is to hard,
# so this script includes the nodejs install as well, which
# is recommended anyways on bitwarden/cli
if [[ "$(uname -s)" == "Darwin" ]]; then
	>&2 echo 'No Darwin Install'
else
  if which snap > /dev/null; then
    sudo snap install bw
  elif which node > /dev/null; then
    npm install -g @bitwarden/cli
    # https://github.com/nvm-sh/nvm#default-global-packages-from-file-while-installing
    >&2 echo ':: SUGGESTION: @bitwarden/cli to $NVM_DIR/default-packages'
  else
    >&2 echo ':: unable to install bitwarden cli'
    exit 1
  fi
fi

#share/applications/bitwarden.desktop
# vim: set ft=bash :
