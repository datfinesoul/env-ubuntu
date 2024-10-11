if [[ "$(uname -s)" == "Darwin" ]]; then
	if [ -f /opt/homebrew/share/bash-completion/bash_completion ]; then
    . /opt/homebrew/share/bash-completion/bash_completion
	fi
fi
