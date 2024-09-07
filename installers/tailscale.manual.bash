#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

curl -fsSL https://tailscale.com/install.sh | sh
