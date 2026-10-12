#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$(uname -s)" == "Darwin" ]]; then
  brew install gh
else
  keyring="/usr/share/keyrings/githubcli-archive-keyring.gpg"

  if ! command -v gh > /dev/null; then
    info ":: installing"
    install_keyring=1
  else
    info ":: updating"
    # Re-fetch keyring if missing/empty or contains any expired keys
    keyring_output="$(sudo gpg --show-keys "${keyring}" 2>/dev/null || true)"
    if [[ -z "${keyring_output}" ]] || grep -q '\[expired' <<<"${keyring_output}"; then
      warn "gh keyring missing or expired, re-fetching"
      install_keyring=1
    fi
  fi

  if [[ "${install_keyring:-0}" -eq 1 ]]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of="${keyring}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${keyring}] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  fi
  sudo apt-get --yes update
  sudo apt-get --yes install gh
fi
