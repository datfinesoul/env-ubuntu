#!/usr/bin/env bash
red="$(tput setaf 1)"
green="$(tput setaf 2)"
yellow="$(tput setaf 3)"
cyan="$(tput setaf 6)"
white="$(tput setaf 7)"
gray="$(tput dim)$(tput setaf 7)"
magenta="$(tput setaf 5)"
reset="$(tput sgr0)"
custom_log() {
	local prefix="$1"
	local postfix="$2"
	shift 2
	if [[ -p /dev/stdin && "$#" -eq 0 ]]; then
		while IFS= read -r line || [ -n "$line" ]; do
			>&2 echo -e "${prefix}${line}${postfix}"
		done
	else
		>&2 echo -e "${prefix}$*${postfix}"
	fi
}
plain() { custom_log "" "" "$@"; }
info() { custom_log "[i] " "" "$@"; }
debug() { custom_log "[${gray}D${reset}]${gray} " "${reset}" "$@"; }
pass() { custom_log "[${green}✔${reset}]${green} " "${reset}" "$@"; }
warn() { custom_log "[${magenta}!${reset}]${magenta} " "${reset}" "$@"; }
fail() { custom_log "[${red}✘${reset}]${red} " "${reset}" "$@"; }
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

kernel_name="$(uname -s)" # Darwin/Linux
machine="$(uname -m)"
if [[ "${machine}" == "x86_64" ]]; then
	architecture="amd64"
else
	architecture="arm64"
fi

debug "kernel_name:  ${kernel_name}"
debug "machine:      ${machine}"
debug "architecture: ${architecture}"

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
debug "script_path:  ${script_path}"
debug "script_name:  ${script_name}"
debug "script_dir:   ${script_dir}"
IFS=$'.' read -r install_name install_type <<< "${script_name%.bash}"
debug "install_name: ${install_name}"
debug "install_type: ${install_type}"

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

if [[ "$(id -u)" -eq "0" ]]; then
	fail "please DO NOT run as root";
	return 1
fi

pid=$$
workdir="/tmp/${install_name}"
install_log="/tmp/${install_name}.log"

# directory that keeps track of successful installs
cache_dir="${script_dir}/cache"
mkdir -p "${cache_dir}"
done="${cache_dir}/${install_name}.done"

# if app was successfully installed it is skipped on re-runs
if [[ "${1:-}" == "--force" ]]; then
	shift
elif [[ -f "${done}" ]]; then
	fail "${install_name}:${pid} skip"
	exit 0
fi

# if we are re-running, delete the previous install working dir
[[ -d "${workdir}" ]] && rm -rf "${workdir}"

# log stdout/stderr to a file and stdout
exec &> >(tee "${install_log}")

function cleanup {
	if [ -n "${1:-}" ]; then
		fail "${install_name}:${pid} Aborted by ${1:-}"
	elif [ "${status}" -ne 0 ]; then
		fail "${install_name}:${pid} Failure (status $status)"
	else
		pass "${install_name}:${pid} Success"
		touch "${done}"
	fi
	popd > /dev/null
}
export -f cleanup
trap 'status=$?; cleanup; exit $status' EXIT
trap 'trap - HUP; cleanup SIGHUP; kill -HUP $$' HUP
trap 'trap - INT; cleanup SIGINT; kill -INT $$' INT
trap 'trap - TERM; cleanup SIGTERM; kill -TERM $$' TERM

mkdir -p "${workdir}"
pushd "${workdir}" > /dev/null
