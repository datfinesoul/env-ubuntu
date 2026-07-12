#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${kernel_name}" == 'Darwin' ]]; then
  brew install tofu-ls
else
	;
fi
