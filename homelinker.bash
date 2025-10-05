#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

# TL;DR: Creates symlinks from $HOME to files/dirs in homelander/_home/
#
# Summary:
#   - Scans homelander/_home/ for files and directories
#   - For files: creates symlink at $HOME/.filename -> homelander/_home/.filename
#   - For dirs: creates directory at $HOME/.dirname/, then symlinks each file inside
#   - Skips existing non-symlink files/dirs to prevent overwriting user data
#

plugin_dir="${script_dir}/homelander/_home"
pushd "$plugin_dir" > /dev/null
find "." -maxdepth 1 -mindepth 1 -print0 \
	| while IFS= read -r -d '' file; do
# skip if empty
[[ ! -e "$file" ]] && continue
link_source="$HOME/${file#*./}"
link_target="$plugin_dir/${file#*./}"
if [[ -d "$file" ]]; then
	mkdir -p "$link_source"

	find "$file/" -maxdepth 1 -mindepth 1 -print0 \
		| while IFS= read -r -d '' file; do
	# skip if empty
	[[ ! -e "$file" ]] && continue
	link_source="$HOME/${file#*./}"
	link_target="$plugin_dir/${file#*./}"

	if [[ -e "$link_source" && ! -h "$link_source" ]]; then
		fail "skip $link_source"
		continue
	fi

	ln -snf "$link_target" "$link_source"
done
else
	link_source="$HOME/${file#*./}"
	link_target="$plugin_dir/${file#*./}"
	if [[ -e "$link_source" && ! -h "$link_source" ]]; then
		fail "skip $link_source"
		continue
	fi

	ln -snf "$link_target" "$link_source"
fi
done

