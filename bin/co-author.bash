#!/usr/bin/env bash
# vi: noet :

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

TYPE="$(git rev-parse HEAD -- &> /dev/null && echo "git" || echo "none")"
# This check has the following purpose
# - Make sure that this is a git repo
# - Make sure that the repo has had a previous commit
# - It uses my git cs alias, because I want the use of this to be intentional
if [[ "${TYPE}" == "git" ]]; then
	TEMPFILE="$(mktemp /tmp/co-author.XXXXXXXX)"
	cat \
		"$(git config commit.template)" \
		<( \
			git shortlog --summary --numbered --email --all \
			| cut -f2- \
			| awk '$0="Co-authored-by: "$0' \
			| fgrep -v "$(git config user.email)" \
			| fzf --multi --exit-0 \
		) \
		> "${TEMPFILE}"
	# TODO: potentially add commit.template to the top later?
	git cs --template="${TEMPFILE}" "$@"
else
	git cs "$@"
fi
