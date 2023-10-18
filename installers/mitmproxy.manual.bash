#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

REPO="mitmproxy/mitmproxy"
TOOLSET="mitmproxy"

# use the passed in version first
VERSION="${1:-}"
if [[ -z "${VERSION}" ]]; then
  # if no version was passed in, look at github
  read -r VERSION URL <<< "$(gh api "/repos/${REPO}/releases/latest" \
    | jq -r '.tag_name' \
  )"
fi
VERSION="${VERSION#*v}"

ZIP_FILE="mitmproxy-${VERSION}-linux.tar.gz"
URL="https://downloads.mitmproxy.org/${VERSION}/${ZIP_FILE}"

TARGET_DIR="${HOME}/.local/${TOOLSET}/${VERSION}"
BIN_DIR="${HOME}/.local/bin"

if [[ "${kernel_name}" == "Darwin" ]]; then
  brew install mitmproxy
else
  mkdir -p "${TARGET_DIR}"
  mkdir -p "${BIN_DIR}"
  >&2 echo ":: fetching ${URL}"
  curl -OL "${URL}"
  tar -zxvf "./${ZIP_FILE}"
  mv mitmdump "${TARGET_DIR}/mitmdump"
  mv mitmproxy "${TARGET_DIR}/mitmproxy"
  mv mitmweb "${TARGET_DIR}/mitmweb"
  ln --symbolic --force "${TARGET_DIR}/mitmdump" "${BIN_DIR}/mitmdump"
  ln --symbolic --force "${TARGET_DIR}/mitmproxy" "${BIN_DIR}/mitmproxy"
  ln --symbolic --force "${TARGET_DIR}/mitmweb" "${BIN_DIR}/mitmweb"
fi
