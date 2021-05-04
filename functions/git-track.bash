git-track () {
	local BRANCH
	BRANCH="$(git branch --show-current)"

	if [[ -n "${BRANCH}" ]]; then
		git branch --set-upstream-to="origin/${BRANCH}" "${BRANCH}"
	else
		>&2 echo "missing branch"
	fi
}
