alias git-branch-age=git_branch_age
git_branch_age () {
eval "$(
	git for-each-ref --shell --format \
	"git --no-pager log -1 --date=iso --format='%%ad '%(align:left,25)%(refname:short)%(end)' %%h %%s' \$(git merge-base %(refname:short) main);" \
	refs/heads
)" | sort
}
