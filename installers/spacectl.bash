#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

TARGET="${1:-/usr/local/bin}/spacectl"
KERNEL_NAME="$(uname -s)" # Darwin/Linux
KERNEL_NAME="${KERNEL_NAME,,}" # darwin/linux
if [[ "$(uname -m)" == "x86_64" ]]; then
  ARCHITECTURE="amd64"
else
  ARCHITECTURE="arm64"
fi
URL="$(curl -sS 'https://api.github.com/repos/spacelift-io/spacectl/releases/latest' \
  | jq --arg k "${KERNEL_NAME}" --arg a \
  "${ARCHITECTURE}" -r '.assets[].browser_download_url | select(test($k+"_"+$a))' \
)"

rm -rf /tmp/spacectl
mkdir -p /tmp/spacectl
cd /tmp/spacectl
wget --quiet "${URL}"
unzip spacectl_*.zip
mv "spacectl" "${TARGET}"
