epoch() {
	local seconds
	if [[ "$1" == '--help' ]]; then
		>&2 echo 'Examples:'
		>&2 echo 'epoch 1656207017'
		>&2 echo 'echo 1656207017 | epoch - +"%Y-%m-%dT%H:%M:%S%z" -u'
	elif [[ "$1" == '-' ]]; then
		seconds="$(</dev/stdin cat)"
	elif [[ -n "$1" ]]; then
		seconds="$1"
	else
		date +%s
		return 0
	fi
	# shift so that any options after $1 are now passed to date for decoding
	shift
	# GNU date vs OSX date
	date -r"${seconds}" "$@" 2> /dev/null \
		|| date --date="@${seconds}" "$@" 2> /dev/null \
		|| return 1
}
