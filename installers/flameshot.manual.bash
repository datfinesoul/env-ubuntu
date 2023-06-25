#!/usr/bin/env bash
# shellcheck disable=SC1091
source '_core.bash'

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install --cask flameshot
else
	sudo apt-get --yes install flameshot
  >&2 echo 'You can add "/usr/bin/flameshot gui" to a custom keybind'
fi
