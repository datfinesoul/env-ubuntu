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
	local root="${1:-${machine_root}}"
	local entry
	for entry in "${root}"/*/; do
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

# Asks for a profile when none is selected. Prints the chosen name on stdout
# and keeps the menu on stderr, so callers can capture the name.
prompt_machine() {
	local name
	local -a profiles=()

	while IFS= read -r name; do
		profiles+=("${name}")
	done < <(available_machines "${machine_root}")

	if [[ "${#profiles[@]}" -eq 0 ]]; then
		fail "no machine profiles exist under ${machine_root}"
		return 1
	fi
	if ! { : < /dev/tty; } 2>/dev/null; then
		fail "no interactive terminal for a machine prompt"
		return 1
	fi

	info "select a machine profile"
	select name in "${profiles[@]}"; do
		if [[ -n "${name}" ]]; then
			printf '%s' "${name}"
			return 0
		fi
		fail "invalid selection"
	done < /dev/tty
	return 1
}

# Returns the selected profile. Prompts when nothing is selected yet.
require_machine() {
	local explicit="${1:-}"
	local resolved

	resolved="$(resolve_machine "${explicit}")"
	if [[ -n "${resolved}" ]]; then
		printf '%s' "${resolved}"
		return 0
	fi
	prompt_machine
}
