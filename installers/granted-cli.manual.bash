#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

REPO="common-fate/granted"
TOOLSET="granted"

# use the passed in version first
VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  # if no version was passed in, look at github
  read -r VERSION URL <<< "$(gh api "/repos/${REPO}/releases/latest" \
    | jq -r '.tag_name' \
  )"
fi
VERSION="${VERSION#*v}"

ZIP_FILE="granted_${VERSION}_${kernel_name,,}_${machine}.tar.gz"
URL="https://releases.commonfate.io/granted/v${VERSION}/${ZIP_FILE}"

TARGET_DIR="${HOME}/.local/${TOOLSET}/${VERSION}"
BIN_DIR="${HOME}/.local/bin"

if [[ "${kernel_name}" == "Darwin" ]]; then
  false
else
  mkdir -p "${TARGET_DIR}"
  mkdir -p "${BIN_DIR}"
  >&2 echo ":: fetching ${URL}"
  curl -OL "${URL}"
  tar -zxvf "./${ZIP_FILE}"
  mv assume "${TARGET_DIR}/assume"
  mv assumego "${TARGET_DIR}/assumego"
  mv granted "${TARGET_DIR}/granted"
  ln --symbolic --force "${TARGET_DIR}/assume" "${BIN_DIR}/assume"
  ln --symbolic --force "${TARGET_DIR}/assumego" "${BIN_DIR}/assumego"
  ln --symbolic --force "${TARGET_DIR}/granted" "${BIN_DIR}/granted"
fi