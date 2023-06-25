#!/usr/bin/env bash
# shellcheck disable=SC1091
source '_core.bash'

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install gh
else
  if [[ "$(which gh > /dev/null && echo "found" || echo "missing")" == "missing" ]]; then
    echo ":: installing"

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  else
    echo ":: updating"
  fi
  sudo apt-get --yes update
  sudo apt-get --yes install gh
fi
