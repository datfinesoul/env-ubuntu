_gs (){
	local tld="$(git rev-parse --show-toplevel 2> /dev/null)" || tld=''
	local command="${1}"
	if [[ -z "${tld}" ]]; then
		return
	fi
	local -a dirs
	IFS=/ read -r -a dirs <<< "$(git rev-parse --show-prefix)"
	local length="${#dirs[@]}"
	local gs_path gs_commands
	for (( i="${#dirs[@]}"; i>=0; i-- )); do
		gs_path="${tld}$(IFS='/'; echo "/${dirs[*]:0:$i}")/gs-targets"
		gs_path="${gs_path//\/\///}"
		#echo $gs_path
		if [[ -e "${gs_path}" ]]; then
			if [[ -n "${command}" && -e "${gs_path}/${command}" ]]; then
				"${tld}/_dev/gs-targets/${command}" "$@"
				return
			fi
			gs_commands+="$(find "${gs_path}/" -type l -exec basename {} \;)\n"
		fi
	done
	if [[ -z "$gs_commands" ]]; then
		>&2 echo "[x] no gs-targets found"
	else
		echo "$gs_commands" | sort | >&2 uniq
	fi
}
gs (){
	local tld="$(git rev-parse --show-toplevel 2> /dev/null)" || tld=''
	local command="${1}"
	if [[ -z "${tld}" ]]; then
		return
	fi
	if [[ ! -e "${tld}/_dev/gs-targets" ]]; then
		>&2 echo ":: missing dir ${tld}/_dev/gs-targets"
		return
	fi
	if [[ -z "${command}" || ! -e "${tld}/_dev/gs-targets/${command}" ]]; then
		>&2 find "${tld}"/_dev/gs-targets -type l -printf '%f\n'
		return
	fi
	shift
	"${tld}/_dev/gs-targets/${command}" "$@"
}
