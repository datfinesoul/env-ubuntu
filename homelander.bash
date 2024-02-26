#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"
if [[ "${1:-}" == '--clean' ]]; then
	clean=true
	shift
fi
dotfile="${1:-}"
target="${2:-${HOME}/${dotfile}}"
plugin_dir="${script_dir}/homelander/${dotfile}"

__usage() {
	plain <<-DOC

	${cyan}./homelander.bash${reset} [--clean] <dotfile> [target]

	${yellow}--clean${reset} removes all previous entries from the target

	DOC
	exit 1
}

if [[ -z "$dotfile" || ! -d "$plugin_dir" ]]; then
	fail 'invalid <dotfile>'
	__usage
fi
if [[ -z "${target}" ]]; then
	__usage
fi

find "${plugin_dir}" -type f -name "*.bash" -print0 \
	| while IFS= read -r -d '' file; do
	# skip if there are no files
	[[ -f "${file}" ]] || continue
	# remove the last .bash from the file name
	label="$(basename "${file%.bash*}")"
	# remove section ( eg. #[+-]:somefile: )
	touch "${target}"
	sed -i '/#[+]:'"${label}"':/,/#[-]:'"${label}"':/d' "${target}"
	if [[ "${clean:-}" == "true" ]]; then
		continue
	fi
	# add the section back
	{
		echo "#+:${label}:"
		# remove blank lines and comments
		sed -e '/^$/d' -e '/^\s*#/d' "${file}"
		echo "#-:${label}:"
	} >> "${target}"
done
