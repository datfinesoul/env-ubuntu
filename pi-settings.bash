#!/usr/bin/env bash
# Renders ~/.pi/agent/settings.json from the shared base plus one machine patch.
#
# This is the single declaration point for the Pi settings mapping. The shared
# base holds keys that are the same on every machine. The machine patch holds
# keys that differ. Runtime keys written by Pi, such as lastChangelogVersion and
# extensionChangelogVersions, appear in neither, so they stay in the live file.
# The theme key is owned by the color-theme function, so it stays local too.
#
# Machine identity comes from, highest precedence first:
#   1. --machine <name>
#   2. ENV_UBUNTU_MACHINE
#   3. ~/.config/env-ubuntu/machine
#
# The resolved name is written back to the local machine file on success.
#
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

render_source="${script_dir}/homelander/_render/.pi/agent/settings.json"
machine_root="${script_dir}/homelander/_machines"
target_file="${HOME}/.pi/agent/settings.json"
machine_file="${HOME}/.config/env-ubuntu/machine"

machine="${ENV_UBUNTU_MACHINE:-}"
dry_run=0

__usage() {
	plain <<-DOC

	${cyan}./pi-settings.bash${reset} [--machine <name>] [--dry-run]

	Render ${target_file} from the shared base and one machine patch.

	DOC
	exit 1
}

available_machines() {
	local entry
	for entry in "${machine_root}"/*/; do
		[[ -d "${entry}" ]] || continue
		basename "${entry}"
	done | sort
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--machine)
			machine="${2:-}"
			shift 2
			;;
		--dry-run)
			dry_run=1
			shift
			;;
		-h|--help)
			__usage
			;;
		*)
			fail "unknown argument: $1"
			__usage
			;;
	esac
done

if [[ -z "${machine}" && -r "${machine_file}" ]]; then
	machine="$(tr -d '[:space:]' < "${machine_file}")"
fi

if [[ -z "${machine}" ]]; then
	fail "no machine profile selected"
	fail "use --machine <name>, set ENV_UBUNTU_MACHINE, or write ${machine_file}"
	fail "available profiles:"
	available_machines | while IFS= read -r name; do fail "  ${name}"; done
	exit 1
fi

machine_patch="${machine_root}/${machine}/_patch"

if [[ ! -d "${machine_patch}" ]]; then
	fail "unknown machine profile: ${machine}"
	fail "available profiles:"
	available_machines | while IFS= read -r name; do fail "  ${name}"; done
	exit 1
fi

patch_file="${machine_patch}/.pi/agent/settings.json"
if [[ ! -r "${patch_file}" ]]; then
	fail "machine profile has no Pi settings patch: ${patch_file}"
	exit 1
fi

case "${machine}" in
	*-linux) expected_kernel="Linux" ;;
	*-mac|-*-macos) expected_kernel="Darwin" ;;
	*) expected_kernel="" ;;
esac
if [[ -n "${expected_kernel}" && "${expected_kernel}" != "${kernel_name}" ]]; then
	warn "profile ${machine} suggests ${expected_kernel}, but this host runs ${kernel_name}"
fi

if [[ "${dry_run}" -eq 1 ]]; then
	info "machine: ${machine}"
	info "[dry-run] would render ${target_file}"
	info "[dry-run] base:  ${render_source}"
	info "[dry-run] patch: ${patch_file}"
	info "[dry-run] would record the machine in ${machine_file}"
	exit 0
fi

"${script_dir}/render.bash" "${render_source}" "${patch_file}" "${target_file}"

mkdir -p -- "$(dirname "${machine_file}")"
if [[ "$(cat -- "${machine_file}" 2>/dev/null || true)" != "${machine}" ]]; then
	printf '%s\n' "${machine}" > "${machine_file}"
fi
pass "machine ${machine}"
