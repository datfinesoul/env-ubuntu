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
  ls /tmp/*.log
  :
}
trap cleanup EXIT

LOG="/tmp/vim-reinstall.bash.log"

# log stdout/stderr to a file and stdout
exec &> >(tee "${LOG}")

# this needs to be cleared to make sure old files are not included in later
# package installations
rm -rf "${HOME}/.vim"

# copy files and dirs to the home folder (additive)
rsync \
  --archive \
  --verbose \
  "./home/.vim" \
  "${HOME}/"
rsync \
  --archive \
  --verbose \
  "./home/.vimrc" \
  "${HOME}/.vimrc"

# vim specific stuff
pushd "${HOME}/.vim/pack/datfinesoul/start/coc.nvim"
npm install
popd
