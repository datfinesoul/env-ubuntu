#!/usr/bin/env bash

alias git-track=git_track
git_track () {
	local BRANCH
	BRANCH="$(git branch --show-current)"

	if [[ -n "${BRANCH}" ]]; then
		git branch --set-upstream-to="origin/${BRANCH}" "${BRANCH}"
	else
		>&2 echo "missing branch"
	fi
}

# Call the function with all arguments
git_track "$@"
