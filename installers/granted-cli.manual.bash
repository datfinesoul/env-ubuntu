#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

REPO="common-fate/granted"

# Only change the above

KERNEL_NAME="$(uname -s)" # Darwin/Linux
MACHINE="$(uname -m)"
if [[ "${MACHINE}" == "x86_64" ]]; then
  ARCHITECTURE="amd64"
else
  ARCHITECTURE="arm64"
fi

# use the passed in version first
VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  # if no version was passed in, look at github
  read -r VERSION URL <<< "$(gh api "/repos/${REPO}/releases/latest" \
    | jq -r '.tag_name' \
  )"
fi
VERSION="${VERSION#*v}"

TOOLSET="granted"

ZIP_FILE="granted_${VERSION}_${KERNEL_NAME,,}_${MACHINE}.tar.gz"
URL="https://releases.commonfate.io/granted/v${VERSION}/${ZIP_FILE}"
>&2 echo ":: fetching ${URL}"

TARGET_DIR="${HOME}/.local/${TOOLSET}/${VERSION}"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${TARGET_DIR}"
mkdir -p "${BIN_DIR}"

if [[ "${KERNEL_NAME}" == "Darwin" ]]; then
  #ln -sf "${TARGET_DIR}/${VERSIONED_EXE}" "${BIN_DIR}/${EXECUTABLE}"
  false
else
  curl -OL "${URL}"
  tar -zxvf "./${ZIP_FILE}"
  mv assume "${TARGET_DIR}/assume"
  mv assumego "${TARGET_DIR}/assumego"
  mv granted "${TARGET_DIR}/granted"
  ln --symbolic --force "${TARGET_DIR}/assume" "${BIN_DIR}/assume"
  ln --symbolic --force "${TARGET_DIR}/assumego" "${BIN_DIR}/assumego"
  ln --symbolic --force "${TARGET_DIR}/granted" "${BIN_DIR}/granted"
fi
