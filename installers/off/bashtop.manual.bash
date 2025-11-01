#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$(uname -s)" == "Darwin" ]]; then
	sudo python3 -m ensurepip
	sudo python3 -m pip install psutil
	brew install bash coreutils gnu-sed git
	brew install osx-cpu-temp
	git clone https://github.com/aristocratos/bashtop.git
	cd bashtop
	sudo make install
else
  sudo add-apt-repository --yes ppa:bashtop-monitor/bashtop
  sudo apt-get --yes update
  sudo apt-get --yes install bashtop
fi
