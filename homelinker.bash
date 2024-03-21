#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

pushd "$HOME"
find "./env-ubuntu/homelander/_home" -maxdepth 1 -mindepth 1 -print0 \
	| while IFS= read -r -d '' file; do
	# skip if empty
	[[ ! -e "$file" ]] && continue
	target="$HOME/$(basename "$file")"
	if [[ -e "$target" && ! -h "$target" ]]; then 
		fail "skip $target"
	       	continue
	fi

	ln -sf "$file" "$HOME/$(basename "$file")"
done
