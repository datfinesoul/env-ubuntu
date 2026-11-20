#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2154
#
# Machine profile helpers. Source this file after _core.bash.
#
# Machine identity comes from, highest precedence first:
#   1. an explicit name passed to resolve_machine
#   2. ENV_UBUNTU_MACHINE
#   3. ~/.config/env-ubuntu/machine
#
# A profile lives at homelander/_machines/<name>/ with an optional _home
# overlay and an optional _patch directory.

machine_root="${script_dir}/homelander/_machines"
machine_record="${HOME}/.config/env-ubuntu/machine"

available_machines() {
	local entry
	for entry in "${machine_root}"/*/; do
		[[ -d "${entry}" ]] || continue
		basename "${entry}"
	done | sort
}

resolve_machine() {
	local explicit="${1:-}"
	local resolved=""

	if [[ -n "${explicit}" ]]; then
		resolved="${explicit}"
	elif [[ -n "${ENV_UBUNTU_MACHINE:-}" ]]; then
		resolved="${ENV_UBUNTU_MACHINE}"
	elif [[ -r "${machine_record}" ]]; then
		resolved="$(tr -d '[:space:]' < "${machine_record}")"
	fi

	printf '%s' "${resolved}"
}
