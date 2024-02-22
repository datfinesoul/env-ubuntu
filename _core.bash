#!/usr/bin/env bash
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
reset="$(tput sgr0)"
plain () { test ! -t 0 && >&2 cat || >&2 echo -e "$*"; }
info () { test ! -t 0 && >&2 sed "s|^|[i] ${1:-}|g" || >&2 echo -e "[i] $*"; }
pass () { >&2 echo "${green}[✔] $*${reset}"; }
fail () { >&2 echo "${red}[✘] $*${reset}"; }
content () { local name="${1}"; printf '%-13s: %s' "${name}" "${!name}"; }
#content () { local name="${1}"; printf '%*s : %s' 12 "${name}" "${!name}"; }
yesno () {
	info "$@"
	>&2 read -r -p "[?] [yes/no]: " yn
}

# Sourced scripts, can use 'return'. In order to not exit the sourced script
#   the 'return test' happens in a subshell
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ "${sourced}" -eq 0 ]]; then
  fail "_core.bash should be sourced"
  exit 1
fi

kernel_name="$(uname -s)" # Darwin/Linux
machine="$(uname -m)"
if [[ "${machine}" == "x86_64" ]]; then
  architecture="amd64"
else
  architecture="arm64"
fi

info "$(content kernel_name)"
info "$(content machine)"
info "$(content architecture)"

if [[ "$(uname -s)" == "Darwin" ]]; then
  function readlink {
    greadlink "$@"
  }
  export -f readlink

  function sed {
    gsed "$@"
  }
  export -f sed
fi

script_path="$(readlink -e -- "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")"
script_name="$(basename "${script_path}")"
script_dir="$(dirname "${script_path}")"
info "$(content script_path)"
info "$(content script_name)"
info "$(content script_dir)"

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

if [[ "$(id -u)" -eq "0" ]]; then
  fail "please DO NOT run as root";
  return 1
fi
