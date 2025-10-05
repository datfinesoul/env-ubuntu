#!/usr/bin/env bash
SCRIPT="$(readlink -e -- "${0}")"
SCRIPT_DIR="$(dirname "${SCRIPT}")"

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

if [[ "${SCRIPT_DIR}" != "$(readlink -e -- "$(pwd)")" ]]; then
  echo "please execute this script from its own directory"
  exit 1
fi

if [[ "$(id -u)" -eq "0" ]]; then
  echo "please DO NOT run as root";
  exit 1
fi

function cleanup {
  :
}
trap cleanup EXIT

<input awk \
    -F'/' \
    '{ print "git@github.com:" $4 "/" $5 ".git"}' \
  | xargs \
    --max-procs=1 \
    --max-lines=1 \
    -I '{}' \
    git clone '{}'
