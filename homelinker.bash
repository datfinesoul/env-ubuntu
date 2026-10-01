#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

# Creates symlinks under $HOME for content in homelander/_home/. Top-level
# directories are materialized so managed entries can coexist with local state.
# Add nested directories to materialized_directories when they also contain a
# mixture of managed configuration and application-generated files.

plugin_dir="${script_dir}/homelander/_home"
materialized_directories=(
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
		fail "skip $link_path"
		return
	fi

	mkdir -p "$(dirname "$link_path")"
	ln -snf "$source" "$link_path"
}

while IFS= read -r -d '' entry; do
	link_entry "$entry"
done < <(find "$plugin_dir" -mindepth 1 -maxdepth 1 -print0)
