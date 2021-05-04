#!/usr/bin/env bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# on mac, most of the scripts require coreutils so this has to happen first
if [[ "$(uname -s)" == "Darwin" ]]; then
  which brew > /dev/null 2>&1 \
    || /bin/bash -c "$( \
    curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh' \
    )"
  brew install coreutils
  PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  export PATH
  echo ':: finished'
fi

SCRIPT="$(readlink -e -- "${0}")"
SCRIPT_DIR="$(dirname "${SCRIPT}")"

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

#cp hidden files
#shopt -s dotglob nullglob
#files=(*)
#echo "There are ${#files[@]} files here, including dot files and subdirs"

LOG="/tmp/bootstrap.bash.log"

# log stdout/stderr to a file and stdout
exec &> >(tee "${LOG}")

if [[ "$(uname -s)" == "Darwin" ]]; then
  true
else
  sudo apt-get --assume-yes update
  sudo apt-get --assume-yes install \
    unzip \
    jq
  sudo apt-get install -o Dpkg::Options::="--force-overwrite" bat ripgrep
  sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install -o Dpkg::Options::="--force-overwrite" bat ripgrep
fi

for SCRIPT in installers/*.install; do
  "${SCRIPT}"
done

exit 1

# this needs to be cleared to make sure old files are not included in later
# package installations
rm -rf "${HOME}/.vim"

# copy files and dirs to the home folder (additive)
rsync \
  --archive \
  --verbose \
  "./home/" \
  "${HOME}"

# vim specific stuff
pushd "${HOME}/.vim/pack/datfinesoul/start/coc.nvim"
npm install
popd

for FILE in bashrc/*.bash; do
  FILE_NAME="$(basename "${FILE}")"
  # remove section in .bashrc ( eg. #:somefile.bash:[+-] )
  sed -i '/#:'"${FILE_NAME}"':[+]/,/#:'"${FILE_NAME}"':[-]/d' "${HOME}/.bashrc"
  # add the section back
  {
    echo "#:${FILE_NAME}:+"
    cat "${FILE}"
    echo "#:${FILE_NAME}:-"
  } >> "${HOME}/.bashrc"
done
