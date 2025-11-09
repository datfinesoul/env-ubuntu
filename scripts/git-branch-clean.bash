#!/usr/bin/env bash

git_branch_clean () {
	local BRANCH
	BRANCH="${1:-main}"

	if [[ -n "${BRANCH}" ]]; then
		git branch --merged "${BRANCH}" \
			| awk '/^\s+/ {print $1}' \
			| xargs -I '{}' git branch -d '{}'
	else
		>&2 echo "missing branch"
	fi
}

git_branch_clean_squashed () {
	local BRANCH
	BRANCH="${1:-main}"

	git checkout -q "${BRANCH}" \
	&& git for-each-ref refs/heads/ "--format=%(refname:short)" \
	| while read branch; do \
		mergeBase=$(git merge-base ${BRANCH} $branch) \
		&& [[ $(git cherry ${BRANCH} $(git commit-tree $(git rev-parse "$branch^{tree}") -p $mergeBase -m _)) == "-"* ]] \
		&& echo "$branch"; \
	done

	>&2 echo "git-branch-clean.bash ${BRANCH} | xargs -I{} -n1 git branch -D {}"
	>&2 echo "git fetch --all && git branch -vv | awk '/: gone]/{print \$1}' | xargs -r git branch -D"
}

# Call the function with all arguments
git_branch_clean "$@"
git_branch_clean_squashed "$@"
