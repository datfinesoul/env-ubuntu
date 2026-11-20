#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"
# shellcheck source=./machine.bash
. "$(dirname "${0}")/machine.bash"

# Creates symlinks under the target directory for content in
# homelander/_home/. A machine overlay at
# homelander/_machines/<machine>/_home/ is linked after the shared tree, so a
# machine entry wins for the whole path it covers.
#
# Top-level directories are materialized so managed entries can coexist with
# local state. A deeper directory is materialized when it is listed in
# materialized_directories or when the machine overlay adds an entry below it.

plugin_dir="${script_dir}/homelander/_home"
target_dir="${HOME}"
machine_home=""
materialized_directories=(
	".config/env-ubuntu"
	".pi/agent"
	".pi/agent/themes"
)
# The empty entry keeps the array safe under `set -u` on older bash.
overlay_materialized=("")

__usage() {
	plain <<-DOC

	${cyan}./homelinker.bash${reset} [--source <dir>] [--target <dir>] [--machine-dir <dir>]

	--source       shared tree, default homelander/_home
	--target       link root, default $HOME
	--machine-dir  machine overlay tree, default from the machine profile

	DOC
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--source)
			plugin_dir="${2:-}"
			shift 2
			;;
		--target)
			target_dir="${2:-}"
			shift 2
			;;
		--machine-dir)
			machine_home="${2:-}"
			shift 2
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

if [[ ! -d "${plugin_dir}" ]]; then
	fail "shared tree not found: ${plugin_dir}"
	exit 1
fi
if [[ -z "${target_dir}" || "${target_dir}" == "/" ]]; then
	fail "refusing to link into: ${target_dir}"
	exit 1
fi

if [[ -z "${machine_home}" ]]; then
	machine_name="$(resolve_machine)"
	if [[ -n "${machine_name}" ]]; then
		machine_home="${machine_root}/${machine_name}/_home"
		if [[ ! -d "${machine_home}" ]]; then
			info "machine ${machine_name} has no _home overlay"
			machine_home=""
		fi
	else
		info "no machine profile selected; linking the shared tree only"
	fi
fi
if [[ -n "${machine_home}" && ! -d "${machine_home}" ]]; then
	fail "machine overlay not found: ${machine_home}"
	exit 1
fi

mkdir -p -- "${target_dir}"

# A shared directory that the machine overlay adds an entry below must be
# materialized, so the machine entry can sit next to the shared entries.
compute_overlay_materialization() {
	local entry relative_path prefix
	local index
	local -a parts

	[[ -n "${machine_home}" ]] || return 0

	while IFS= read -r -d '' entry; do
		relative_path="${entry#"${machine_home}/"}"
		[[ "${relative_path}" == "${entry}" ]] && continue
		parts=()
		IFS='/' read -r -a parts <<< "${relative_path}"
		prefix=""
		for ((index = 0; index < ${#parts[@]} - 1; index++)); do
			prefix="${prefix:+${prefix}/}${parts[index]}"
			if [[ -d "${plugin_dir}/${prefix}" ]]; then
				overlay_materialized+=("${prefix}")
			fi
		done
	done < <(find "${machine_home}" -mindepth 1 -print0)
}

should_materialize() {
	local relative_path="$1"
	local configured_path

	[[ "$relative_path" != */* ]] && return 0
	for configured_path in "${materialized_directories[@]}"; do
		[[ "$relative_path" == "$configured_path" ]] && return 0
	done
	for configured_path in "${overlay_materialized[@]}"; do
		[[ -n "$configured_path" && "$relative_path" == "$configured_path" ]] && return 0
	done
	return 1
}

# LEGACY MIGRATION SUPPORT
#
# Older versions of homelinker represented a repository-owned directory as a
# real directory tree containing individual symlinks for its files. The current
# approach links the repository-owned directory itself, which is much faster.
# is_managed_container identifies those previously materialized trees so
# link_entry can migrate them to a single directory symlink without deleting
# local files.
#
# Once every computer has run this migration successfully, remove the
# is_managed_container function and the marked LEGACY MIGRATION branch in
# link_entry. Existing directory conflicts will then take the normal,
# conservative `skip` path.
#
# Arguments:
#   $1 (source) - repository directory that the new symlink will point to
#   $2 (target) - existing directory under the target root that may be replaced
#
# Returns success only when every entry below target is one of:
#   * a real directory, used only to organize managed links; or
#   * a symlink that resolves to source itself or to something below source.
#
# A regular file, special file, broken link, or link outside source returns
# failure. link_entry then preserves the entire target directory. An empty
# target is considered safe because it contains no local state to preserve.
#
is_managed_container() {
	local source="$1"
	local target="$2"
	local entry resolved

	# find emits NUL-delimited names so paths with spaces or newlines work.
	# Process substitution keeps the loop in this shell, so `return 1` returns
	# from this function rather than from a pipeline subshell.
	while IFS= read -r -d '' entry; do
		# Ordinary directories are structural; find also checks their contents.
		[[ -d "$entry" && ! -h "$entry" ]] && continue

		# Anything other than a directory or symlink is local state.
		[[ -h "$entry" ]] || return 1

		# -e resolves the complete link and fails for a broken link.
		resolved="$(readlink -e -- "$entry")" || return 1

		# Avoid a simple string-prefix test: /source-other is not below /source.
		[[ "$resolved" == "$source" || "$resolved" == "$source/"* ]] || return 1
	done < <(find "$target" -mindepth 1 -print0)
	return 0
}

link_entry() {
	local root="$1"
	local source="$2"
	local relative_path="${source#"${root}/"}"
	local link_path="${target_dir}/${relative_path}"
	local child

	if [[ -d "$source" ]] && should_materialize "$relative_path"; then
		if [[ -h "$link_path" ]]; then
			rm "$link_path"
		elif [[ -e "$link_path" && ! -d "$link_path" ]]; then
			fail "skip $link_path"
			return
		fi
		mkdir -p "$link_path"
		while IFS= read -r -d '' child; do
			link_entry "$root" "$child"
		done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
		return
	fi

	if [[ -e "$link_path" && ! -h "$link_path" ]]; then
		# LEGACY MIGRATION: collapse an old tree of managed links to one link.
		# Remove this branch together with is_managed_container after all hosts
		# have migrated; the `else` branch is the permanent safety behavior.
		if [[ -d "$source" && -d "$link_path" ]] && is_managed_container "$source" "$link_path"; then
			rm -rf "$link_path"
		else
			fail "skip $link_path"
			return
		fi
	fi

	mkdir -p "$(dirname "$link_path")"
	ln -snf "$source" "$link_path"
}

# True when a parent of the path is a symlink. Writing through such a link
# would place a file inside the linked directory, possibly inside the repo.
ancestor_symlink() {
	local current
	current="$(dirname "$1")"
	while [[ "${current}" != "${target_dir}" && "${current}" != "/" ]]; do
		[[ -h "${current}" ]] && return 0
		current="$(dirname "${current}")"
	done
	return 1
}

# Machine overlay entries replace repository symlinks. Any other existing
# target is local state and stays untouched.
link_overlay_entry() {
	local source="$1"
	local relative_path="${source#"${machine_home}/"}"
	local link_path="${target_dir}/${relative_path}"
	local child

	if [[ -d "$source" ]] && should_materialize "$relative_path"; then
		if [[ -h "$link_path" ]]; then
			rm "$link_path"
		elif [[ -e "$link_path" && ! -d "$link_path" ]]; then
			fail "skip $link_path"
			return
		fi
		mkdir -p "$link_path"
		while IFS= read -r -d '' child; do
			link_overlay_entry "$child"
		done < <(find "$source" -mindepth 1 -maxdepth 1 -print0)
		return
	fi

	if ancestor_symlink "$link_path"; then
		fail "skip $link_path: parent directory is a symlink"
		return
	fi

	if [[ -h "$link_path" ]]; then
		rm "$link_path"
	elif [[ -e "$link_path" ]]; then
		fail "skip $link_path"
		return
	fi

	mkdir -p "$(dirname "$link_path")"
	ln -snf "$source" "$link_path"
}

compute_overlay_materialization

while IFS= read -r -d '' entry; do
	link_entry "${plugin_dir}" "$entry"
done < <(find "${plugin_dir}" -mindepth 1 -maxdepth 1 -print0)

if [[ -n "${machine_home}" ]]; then
	while IFS= read -r -d '' entry; do
		link_overlay_entry "$entry"
	done < <(find "${machine_home}" -mindepth 1 -maxdepth 1 -print0)
fi
