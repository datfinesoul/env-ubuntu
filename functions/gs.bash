gs () {
	# Exit if git isn't available
	if ! type git &> /dev/null; then return 1; fi
	# Get the top level git directory absolute path or exit if this is not a git repo
	local tld="$(git rev-parse --show-toplevel 2> /dev/null)" || tld=''
	if [[ -z "${tld}" ]]; then
		return 1
	fi
	# Example: if 'git rev-parse --show-prefix' returns 'src/utils/',
	#   then the 'dirs' array will contain ['src', 'utils'].
	local -a dirs
	IFS=/ read -r -a dirs <<< "$(git rev-parse --show-prefix)"

	# Construct the path to a potential '_gs' directory by combining the
	# top-level directory 'tld' with progressively shorter segments
	# of the repository-relative path 'dirs'. This helps locate '_gs'
	# directories closer to the current path.
	local gs_path gs_commands index
	local command="${1:-}"
	local length="${#dirs[@]}"
	for (( index="${length}"; index>=0; index-- )); do
		# Example: if the 'dirs' array contains ['src', 'utils'], this
		#   will assign '$tld/src/utils/_gs' to 'gs_path'
		gs_path="${tld}$(printf "/%s" "${dirs[@]:0:$index}")/_gs"
		gs_path="${gs_path//\/\//\/}"

		if [[ -e "${gs_path}" ]]; then
			# If a _gs command was passed in $1 execute it and leave the function
			if [[ -n "${command}" && -e "${gs_path}/${command}" ]]; then
				"${gs_path}/${command}" "$@"
				return
			fi
			# No matching command was executed so add the commands in this
			#   _gs dir to a collection of commands
			gs_commands+="$(find "${gs_path}/" -type l ! -xtype l -perm -111 -exec basename {} \;)"$'\n'
		fi
	done
	# Either exit because no command was found or print the list of commands
	if [[ -z "$gs_commands" ]]; then
		>&2 echo "[x] no _gs commands found"
	else
		# print the collection
		echo -e "$gs_commands" | sort | >&2 uniq
	fi
}
