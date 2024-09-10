gs (){
	local tld="$(git rev-parse --show-toplevel 2> /dev/null)" || tld=''
	local command="${1}"
	if [[ -z "${tld}" ]]; then
		return
	fi
	local -a dirs
	# load an array with each part of the repo based relative path
	IFS=/ read -r -a dirs <<< "$(git rev-parse --show-prefix)"
	local length="${#dirs[@]}"
	local gs_path gs_commands
	for (( i="${length}"; i>=0; i-- )); do
		# starting with the longest path, find a _gs dir
		gs_path="${tld}$(IFS='/'; echo "/${dirs[*]:0:$i}")/_gs"
		gs_path="${gs_path//\/\///}"
		#echo "==$gs_path"
		if [[ -e "${gs_path}" ]]; then
			# if a _gs command was passed in $1 execute it
			if [[ -n "${command}" && -e "${gs_path}/${command}" ]]; then
				"${gs_path}/${command}" "$@"
				return
			fi
			# otherwise add the commands in this dir to a collection
			gs_commands+="$(find "${gs_path}/" -type l -exec basename {} \;)"$'\n'
		fi
	done
	if [[ -z "$gs_commands" ]]; then
		>&2 echo "[x] no _gs commands found"
	else
		# print the collection
		echo -e "$gs_commands" | sort | >&2 uniq
	fi
}
