#!/usr/bin/env bash
# Runs every test/*.test.bash file with a plain bash runner.
#
# shellcheck shell=bash

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

test_dir="$(cd "$(dirname "${0}")" && pwd)"
REAL_HOME="${HOME}"
export REAL_HOME

status=0
for test_file in "${test_dir}"/*.test.bash; do
	printf '== %s\n' "$(basename "${test_file}")"
	if ! bash "${test_file}"; then
		status=1
	fi
done

exit "${status}"
