#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# Install it on a well known system path that will work on most systems
curl \
  -L https://raw.githubusercontent.com/nickjj/plutus/0.7.2/src/plutus \
  -o "$HOME/.local/bin/plutus" && chmod +x "$HOME/.local/bin/plutus"
