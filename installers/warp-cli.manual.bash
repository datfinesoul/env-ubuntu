#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$(uname -s)" == "Darwin" ]]; then
  :
else
  if which warp-cli &> /dev/null; then
    echo "already installed"
    exit 1
  fi
  sudo apt-get --yes install \
    'curl' \
    'gnupg'

  curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg \
    | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/cloudflare-client.list > /dev/null

  sudo apt-get --yes update
  sudo apt-get --yes install cloudflare-warp
fi

# vim: set ft=bash :
