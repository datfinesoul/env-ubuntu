#!/usr/bin/env bash
# Shared helpers for the plain-bash test suite.
#
# Every test runs with a temporary $HOME. The helper refuses to run when $HOME
# still points at the real home directory (voight2.md section 13).
#
# shellcheck shell=bash disable=SC2034

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_HOME="${REAL_HOME:-${HOME}}"

test_count=0
test_failures=0
cleanup_paths=()

test_cleanup() {
	local path
	for path in "${cleanup_paths[@]}"; do
		[[ -d "${path}" ]] && rm -rf -- "${path}"
	done
}
trap test_cleanup EXIT

new_temp_dir() {
	local dir
	dir="$(mktemp -d)"
	cleanup_paths+=("${dir}")
	printf '%s' "${dir}"
}

use_temp_home() {
	local dir
	dir="$(new_temp_dir)"
	HOME="${dir}/home"
	mkdir -p "${HOME}"
	export HOME
	if [[ "${HOME}" == "${REAL_HOME}" || "${HOME}" == "/" ]]; then
		printf 'refusing to use the real home directory\n' >&2
		exit 1
	fi
}

check_equal() {
	local label="$1"
	local expected="$2"
	local actual="$3"

	test_count=$((test_count + 1))
	if [[ "${expected}" == "${actual}" ]]; then
		printf 'ok   %s\n' "${label}"
	else
		test_failures=$((test_failures + 1))
		printf 'FAIL %s\n' "${label}"
		printf '  expected: %s\n' "${expected}"
		printf '  actual:   %s\n' "${actual}"
	fi
}

check_json_equal() {
	local label="$1"
	local expected="$2"
	local actual_file="$3"

	check_equal "${label}" "${expected}" "$(jq -S -c . "${actual_file}")"
}

check_contains() {
	local label="$1"
	local needle="$2"
	local haystack="$3"

	test_count=$((test_count + 1))
	if [[ "${haystack}" == *"${needle}"* ]]; then
		printf 'ok   %s\n' "${label}"
	else
		test_failures=$((test_failures + 1))
		printf 'FAIL %s\n' "${label}"
		printf '  missing: %s\n' "${needle}"
		printf '  in:      %s\n' "${haystack}"
	fi
}

check_file_exists() {
	local label="$1"
	local path="$2"

	test_count=$((test_count + 1))
	if [[ -f "${path}" ]]; then
		printf 'ok   %s\n' "${label}"
	else
		test_failures=$((test_failures + 1))
		printf 'FAIL %s\n' "${label}"
		printf '  missing file: %s\n' "${path}"
	fi
}

check_file_absent() {
	local label="$1"
	local path="$2"

	test_count=$((test_count + 1))
	if [[ -e "${path}" || -h "${path}" ]]; then
		test_failures=$((test_failures + 1))
		printf 'FAIL %s\n' "${label}"
		printf '  unexpected file: %s\n' "${path}"
	else
		printf 'ok   %s\n' "${label}"
	fi
}

check_symlink() {
	local label="$1"
	local path="$2"

	test_count=$((test_count + 1))
	if [[ -h "${path}" ]]; then
		printf 'ok   %s\n' "${label}"
	else
		test_failures=$((test_failures + 1))
		printf 'FAIL %s\n' "${label}"
		printf '  not a symlink: %s\n' "${path}"
	fi
}

check_not_symlink() {
	local label="$1"
	local path="$2"

	test_count=$((test_count + 1))
	if [[ -h "${path}" ]]; then
		test_failures=$((test_failures + 1))
		printf 'FAIL %s\n' "${label}"
		printf '  still a symlink: %s\n' "${path}"
	else
		printf 'ok   %s\n' "${label}"
	fi
}

finish() {
	printf '\n%d checks, %d failed\n' "${test_count}" "${test_failures}"
	[[ "${test_failures}" -eq 0 ]]
}
