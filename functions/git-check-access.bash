git-check-access () {
	REPO="${1}"
	GIT_SSH_COMMAND="ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no " \
		git ls-remote "git@github.com:${REPO}.git" &> /dev/null \
		&& echo "yay" \
		|| echo "nay"

	# TODO: make output return: none, http, ssh, full
}
