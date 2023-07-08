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
