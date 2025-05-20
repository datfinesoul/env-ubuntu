#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2312
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
	if [[ -p /dev/stdin && $# -eq 0 ]]; then
		while IFS= read -r line || [ -n "$line" ]; do
			echo >&2 -e "${prefix}${line}${postfix}"
		done
	else
		echo >&2 -e "${prefix}$*${postfix}"
	fi
}
plain() { custom_log "" "" "$@"; }
info() { custom_log "[i] " "" "$@"; }
debug() { custom_log "[${gray}D${reset}]${gray} " "${reset}" "$@"; }
pass() { custom_log "[${green}✔${reset}]${green} " "${reset}" "$@"; }
warn() { custom_log "[${magenta}!${reset}]${magenta} " "${reset}" "$@"; }
fail() { custom_log "[${red}✘${reset}]${red} " "${reset}" "$@"; }
yesno() {
	info "$@"
	read >&2 -r -p "[?] [yes/no]: " yn
}
content() {
	local name="${1}"
	printf '%-13s: %s' "${name}" "${!name}"
}

# Sourced scripts, can use 'return'. In order to not exit the sourced script
#   the 'return test' happens in a subshell
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ ${sourced} -eq 0 ]]; then
	fail "_core.bash should be sourced"
	exit 1
fi

kernel_name="$(uname -s)" # Darwin/Linux
machine="$(uname -m)"
if [[ ${machine} == "x86_64" ]]; then
	architecture="amd64"
else
	architecture="arm64"
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

script_path="$(readlink -e -- "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")"
script_name="$(basename "${script_path}")"
script_dir="$(dirname "${script_path}")"

if [[ -n ${DEBUG_ENV-} ]]; then
	info "$(content kernel_name)"
	info "$(content machine)"
	info "$(content architecture)"
	info "$(content script_path)"
	info "$(content script_name)"
	info "$(content script_dir)"
fi

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
# shopt -s inherit_errexit # bash 4.4+
IFS=$'\n\t'

if [[ "$(id -u)" -eq "0" ]]; then
	fail "please DO NOT run as root"
	return 1
fi
