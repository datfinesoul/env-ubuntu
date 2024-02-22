#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# # type git
# #   that installs development tools
# # then clone
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# remap caps lock to esc
# the below option might be the linux version
#setxkbmap -option caps:escape
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'

chsh -s /bin/bash
touch ~/.bash_sessions_disable
brew install coreutils gnu-sed jq

# this is supposed to fail to confirm a version of readlink is not in the path
type -t readlink || true

# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

type -t readlink

if [[ "${script_dir}" != "$(readlink -e -- "$(pwd)")" ]]; then
  fail "please execute this script from its own directory"
  exit 1
fi

if [[ "$(id -u)" -eq "0" ]]; then
  fail "please DO NOT run as root";
  exit 1
fi

if [[ "${kernel_name}" == 'Darwin' ]]; then
  "${script_dir}/homelander.bash" .bash_profile
fi
"${script_dir}/homelander.bash" .bashrc

function cleanup {
  ls /tmp/*.log
  :
}
trap cleanup EXIT

install_log="/tmp/bootstrap.bash.log"

# log stdout/stderr to a file and stdout
exec &> >(tee "${install_log}")

for install_script in installers/*.auto.bash; do
  "${install_script}"
done
