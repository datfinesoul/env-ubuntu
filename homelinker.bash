#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

# Creates symlinks under $HOME for content in homelander/_home/. Top-level
# directories are materialized so managed entries can coexist with local state.
# Add nested directories to materialized_directories when they also contain a
# mixture of managed configuration and application-generated files.

plugin_dir="${script_dir}/homelander/_home"
materialized_directories=(
	".config/env-ubuntu"
	".pi/agent"
	".pi/agent/themes"
)

should_materialize() {
	local relative_path="$1"
	local configured_path

	[[ "$relative_path" != */* ]] && return 0
	for configured_path in "${materialized_directories[@]}"; do
		[[ "$relative_path" == "$configured_path" ]] && return 0
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
# link_entry. Existing directory
# conflicts will then take the normal, conservative `skip` path.
#
# Arguments:
#   $1 (source) - repository directory that the new symlink will point to
#   $2 (target) - existing directory under $HOME that may be replaced
#
# Returns success only when every entry below target is one of:
#   * a real directory, used only to organize managed links; or
#   * a symlink that resolves to source itself or to something below source.
#
# A regular file, special file, broken link, or link outside source returns
# failure. link_entry then preserves the entire target directory. An empty
# target is considered safe because it contains no local state to preserve.
#
# find emits NUL-delimited names so paths containing spaces or newlines work.
# Process substitution keeps the loop in this shell, allowing `return 1` to
# return from this function rather than from a pipeline subshell.
is_managed_container() {
	local source="$1"
	local target="$2"
	local entry resolved

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
	local source="$1"
	local relative_path="${source#"${plugin_dir}/"}"
	local link_path="${HOME}/${relative_path}"
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
			link_entry "$child"
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

while IFS= read -r -d '' entry; do
	link_entry "$entry"
done < <(find "$plugin_dir" -mindepth 1 -maxdepth 1 -print0)
