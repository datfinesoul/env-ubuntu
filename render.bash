#!/usr/bin/env bash
# Renders a JSON settings file from a shared base and a machine patch.
#
# Contract:
#   desired = deep_merge(base, patch)      # patch wins, arrays replace
#   result  = deep_merge(target, desired)  # desired wins, target-only keys stay
#
# Keys in base or patch are managed. Keys in neither are owned by the app or
# the user, so they survive a render. A "null" patch value does not delete a
# key yet; that policy is still an open question.
#
# The target is written only when its content changes, so a second run is a
# no-op. The write is atomic: a temporary file in the target directory, then a
# rename. An existing target keeps its mode. A new target gets mode 0600
# because settings files can hold sensitive values.
#
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

__usage() {
	plain <<-DOC

	${cyan}./render.bash${reset} <base.json> <patch.json> <target.json>

	Merge <base.json> and <patch.json> into <target.json>.
	<target.json> keeps keys that the base and patch do not manage.

	DOC
	exit 1
}

remove_tmp() {
	if [[ -n "${render_tmp:-}" ]]; then
		rm -f -- "${render_tmp}"
	fi
	return 0
}

file_mode() {
	local path="$1"
	if [[ "${kernel_name}" == "Darwin" ]]; then
		stat -f '%Lp' -- "${path}"
	else
		stat -c '%a' -- "${path}"
	fi
}

render_base="${1:-}"
render_patch="${2:-}"
render_target="${3:-}"

if [[ -z "${render_base}" || -z "${render_patch}" || -z "${render_target}" ]]; then
	__usage
fi

if ! command -v jq > /dev/null 2>&1; then
	fail "jq is required to render JSON settings"
	exit 1
fi
if [[ ! -r "${render_base}" ]]; then
	fail "cannot read base: ${render_base}"
	exit 1
fi
if [[ ! -r "${render_patch}" ]]; then
	fail "cannot read patch: ${render_patch}"
	exit 1
fi
if ! jq -e 'type == "object"' "${render_base}" > /dev/null; then
	fail "base is not a JSON object: ${render_base}"
	exit 1
fi
if ! jq -e 'type == "object"' "${render_patch}" > /dev/null; then
	fail "patch is not a JSON object: ${render_patch}"
	exit 1
fi

# Migrate a symlink that points into this repository. Any other symlink is
# local state and stays untouched.
if [[ -h "${render_target}" ]]; then
	render_resolved="$(readlink -f -- "${render_target}")"
	if [[ "${render_resolved}" == "${script_dir}"/* ]]; then
		info "replacing repository symlink ${render_target}"
		rm -f -- "${render_target}"
	else
		fail "skip ${render_target}: symlink points outside the repository (${render_resolved})"
		exit 1
	fi
fi

render_dir="$(dirname "${render_target}")"
mkdir -p -- "${render_dir}"

render_tmp="$(mktemp "${render_dir}/.render.XXXXXX")"
trap 'remove_tmp; _core_cleanup' EXIT

if [[ -s "${render_target}" ]]; then
	render_program='$target[0] * $base[0] * $patch[0]'
	jq -n --slurpfile base "${render_base}" \
		--slurpfile patch "${render_patch}" \
		--slurpfile target "${render_target}" \
		"${render_program}" > "${render_tmp}"
else
	render_program='$base[0] * $patch[0]'
	jq -n --slurpfile base "${render_base}" \
		--slurpfile patch "${render_patch}" \
		"${render_program}" > "${render_tmp}"
fi

if [[ -e "${render_target}" ]] && cmp -s -- "${render_tmp}" "${render_target}"; then
	remove_tmp
	render_tmp=""
	pass "unchanged ${render_target}"
	exit 0
fi

if [[ -e "${render_target}" ]]; then
	chmod -- "$(file_mode "${render_target}")" "${render_tmp}"
else
	chmod 600 "${render_tmp}"
fi
mv -f -- "${render_tmp}" "${render_target}"
render_tmp=""
pass "rendered ${render_target}"
