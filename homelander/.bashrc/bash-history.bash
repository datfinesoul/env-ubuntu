# History date format
export HISTTIMEFORMAT="%y/%m/%d %T "
# Ignore leading-space commands and consecutive duplicates. Deduplicate on logout.
export HISTCONTROL="ignoreboth"
# Number of commands to save
export HISTSIZE=50000
# History maxiumum file size
export HISTFILESIZE=50000
# Ignore exit commands from history
export HISTIGNORE="&:[ ]*:exit"
# Never overwrise history, always append
shopt -s histappend
# Multiline commands become one line
shopt -s cmdhist

# Remove a failed command only when Bash added one history entry.
__env_ubuntu_filter_history() {
	local status=$1 last=$((HISTCMD - 1)) entry
	if (( BASH_VERSINFO[0] < 4 )); then
		# Bash 3 does not update HISTCMD inside PROMPT_COMMAND.
		entry=$(HISTTIMEFORMAT='' history 1)
		IFS=$' \t' read -r last _ <<< "$entry"
		last=${last:-0}
	fi
	if [[ -n ${__env_ubuntu_history_last+x} ]] &&
		(( status != 0 && last > 0 && last == __env_ubuntu_history_last + 1 )); then
		if history -d "$last"; then
			last=$((last - 1))
		fi
	fi
	__env_ubuntu_history_last=$last
	return "$status"
}

if [[ $- == *i* ]]; then
	PROMPT_COMMAND='__env_ubuntu_filter_history "$?"'"${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
	bind '"\e[A":history-search-backward'
	bind '"\e[B":history-search-forward'
fi
