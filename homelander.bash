#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"
dotfile="${1:-}"
target="${2:-${HOME}/${dotfile}}"
plugin_dir="${script_dir}/homelander/${dotfile}"

__usage() {
	plain <<-DOC

	${cyan}./homelander.bash${reset} <dotfile> [target]

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

info "homelander starting"
# remove all the previously added entries
sed -i '/^#[+]:[^:]\+:$/,/^#[-]:[^:]\+:$/d' "$target"
# add things back
find "${plugin_dir}" -type f -name "*.bash" -print0 \
	| sort -z \
	| while IFS= read -r -d '' file; do
	# skip if there are no files
	[[ -f "${file}" ]] || continue
	# remove the last .bash from the file name
	label="$(basename "${file%.bash*}")"
	# remove section ( eg. #[+-]:somefile: )
	touch "${target}"
	# add the section back
	{
		echo "#+:${label}:"
		# remove blank lines and comments
		sed -e '/^$/d' -e '/^\s*#/d' "${file}"
		echo "#-:${label}:"
	} >> "${target}"
done
info "homelander finished"
