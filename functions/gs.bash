gs() {
	# Exit if git isn't available
	if ! type git &> /dev/null; then return 1; fi

	# Get the top level git directory absolute path or exit if not a git repo
	local tld
	tld="$(git rev-parse --show-toplevel 2> /dev/null)" || return 1
	[[ -z "${tld}" ]] && return 1

	# Parse current path relative to repo root into array
	local -a dirs
	IFS=/ read -r -a dirs <<< "$(git rev-parse --show-prefix)"

	local gs_path gs_commands index
	local command="${1:-}"
	local length="${#dirs[@]}"

	# Search for _gs directories from current path up to repo root
	for (( index="${length}"; index>=0; index-- )); do
		gs_path="${tld}$(printf "/%s" "${dirs[@]:0:$index}")/_gs"
		gs_path="${gs_path//\/\//\/}"

		if [[ -e "${gs_path}" ]]; then
			# Execute command if it exists
			if [[ -n "${command}" && -e "${gs_path}/${command}" ]]; then
				shift
				"${gs_path}/${command}" "$@"
				return
			fi

			# Otherwise collect available commands with their targets
			gs_commands+="$(find "${gs_path}/" -type l ! -xtype l -perm -111 -exec sh -c '
				repo_root=$(git rev-parse --show-toplevel)
				target=$(readlink -f "$1")
				target_rel=${target#"$repo_root/"}
				gs_link="$(basename "$1")"
				echo "$gs_link -> $target_rel"
				' _ {} \;
			)"$'\n'
		fi
	done

	# Display results or error
	if [[ -z "${gs_commands}" ]]; then
		echo >&2 "[x] no _gs commands found"
	else
		awk '!seen[$1]++' <<< "${gs_commands}" | sort
		echo
	fi
}
