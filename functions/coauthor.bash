coauthor () {
local STATUS ROOT_DIR COAUTHORS

git rev-parse HEAD -- > /dev/null 2>&1
STATUS="$?"

if [[ "${STATUS}" -ne 0 ]]; then
	# Use the regular git command if:
	# - This is not a GIT repo (so that you get normal errors)
	# - This repo has not yet had a commit
	git cs "$@"
	return
fi

ROOT_DIR="."
if [[ "${1:-}" == "--all" ]]; then
	ROOT_DIR="$(git rev-parse --show-toplevel)"
fi

COAUTHORS="$(mktemp /tmp/co-author.XXXXXXXX)"
{
	cat "$(git config commit.template)"
	git shortlog --summary --numbered --email --all "${ROOT_DIR}" \
		| cut -f2- \
		| awk '$0="Co-authored-by: "$0' \
		| fgrep -v "$(git config user.email)" \
		| fzf --multi --exit-0 --no-sort
} > "${COAUTHORS}"
git cs --template="${COAUTHORS}" "$@"
}
