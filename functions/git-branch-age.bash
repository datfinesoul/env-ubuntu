alias git-branch-age=git_branch_age
git_branch_age () {
	git for-each-ref \
		--sort=creatordate \
		--format='%(committerdate:format:%Y-%m-%d %H:%M) %(refname:short) | %(subject)' \
		refs/heads \
		refs/remotes | \
		awk 'BEGIN { "tput cols" | getline cols; cols = int(cols); if (cols == 0) cols = 80 } { if (length($0) > cols - 3) print substr($0, 1, cols - 3) "…"; else print }'
}
