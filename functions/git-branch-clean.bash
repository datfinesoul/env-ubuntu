git-branch-clean () {
	local BRANCH
	BRANCH="${1}"

	if [[ -n "${BRANCH}" ]]; then
		git branch --merged "${BRANCH}" \
			| awk '/^\s+/ {print $1}' \
			| xargs -I '{}' git branch -d '{}'
	else
		>&2 echo "missing branch"
	fi
}

git-branch-clean-squashed () {
	local BRANCH
	BRANCH="${1:-main}"

	git checkout -q "${BRANCH}" \
	&& git for-each-ref refs/heads/ "--format=%(refname:short)" \
	| while read branch; do \
		mergeBase=$(git merge-base ${BRANCH} $branch) \
		&& [[ $(git cherry ${BRANCH} $(git commit-tree $(git rev-parse "$branch^{tree}") -p $mergeBase -m _)) == "-"* ]] \
		&& echo "$branch"; \
	done

	>&2 echo "git-branch-clean-squashed ${BRANCH} | xargs -I{} -n1 git branch -D {}"
}
