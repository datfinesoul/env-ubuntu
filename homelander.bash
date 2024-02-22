#!/usr/bin/env bash
# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"
dotfile="${1}"
target="${2:-${HOME}}/${dotfile}"
# TODO: add option to override comment style

for file in "${script_dir}/homelander/${dotfile}"/*.bash; do
  # skip if there are no files
  [[ -f "${file}" ]] || continue
  # remove the last .bash from the file name
  label="$(basename "${file%.bash*}")"
  # remove section ( eg. #[+-]:somefile: )
  touch "${target}"
  sed -i '/#[+]:'"${label}"':/,/#[-]:'"${label}"':/d' "${target}"
  # add the section back
  {
    echo "#+:${label}:"
    # remove blank lines and comments
    sed -e '/^$/d' -e '/^\s*#/d' "${file}"
    echo "#-:${label}:"
  } >> "${target}"
done
