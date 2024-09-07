#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
IFS=$'\n\t'

# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# this is supposed to confirm a version of readlink is in the path
type -t readlink

if [[ "${script_dir}" != "$(readlink -e -- "$(pwd)")" ]]; then
  fail "please execute this script from its own directory"
  exit 1
fi

if [[ "$(id -u)" -eq "0" ]]; then
  fail "please DO NOT run as root";
  exit 1
fi

echo "export ENV_UBUNTU_ROOT='$script_dir'" \
	> "$script_dir/homelander/.bashrc/0-env-ubuntu-root.bash"
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
