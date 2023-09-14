#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# TODO: Create a .env-ubuntu/version-config.json or something similar to manage
#       installation preferences
VERSION="${1:-1.5.5}"
TF_DIR="${HOME}/.local/terraform"
BIN_DIR="${HOME}/.local/bin"
TF_EXE="${TF_DIR}/terraform_${VERSION}"
mkdir -p "${TF_DIR}"
mkdir -p "${BIN_DIR}"

# cleanup old installations
if [[ -f /usr/local/bin/terraform ]]; then
  sudo rm /usr/local/bin/terraform
fi
if [[ -h /usr/local/bin/tf ]]; then
  sudo rm /usr/local/bin/tf
fi

if [[ ! -f "${TF_EXE}" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    wget \
      --quiet \
      "$(printf '%s' \
      "https://releases.hashicorp.com/terraform" \
      "/${VERSION}/terraform_${VERSION}_darwin_amd64.zip" \
      )"
  else
    ARCHITECTURE="$(dpkg --print-architecture)"
    wget \
      --quiet \
      "$(printf '%s' \
      "https://releases.hashicorp.com/terraform" \
      "/${VERSION}/terraform_${VERSION}_linux_${ARCHITECTURE}.zip" \
      )"
  fi
  unzip terraform_*.zip
  mv terraform "${TF_EXE}"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  ln -sf "${TF_EXE}" "${BIN_DIR}/terraform"
  ln -sf "${TF_EXE}" "${BIN_DIR}/tf"
else
  ln --symbolic --force "${TF_EXE}" "${BIN_DIR}/terraform"
  ln --symbolic --force "${TF_EXE}" "${BIN_DIR}/tf"
fi

mkdir -p "${HOME}/.terraform.d/plugin-cache"

# vim: set ft=bash :
