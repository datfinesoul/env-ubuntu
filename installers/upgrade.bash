#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_logging.bash"

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

script_path="$(readlink -e -- "${BASH_SOURCE[0]}")"
script_dir="$(dirname "${script_path}")"
cache_dir="${script_dir}/cache"

if [[ ! -d "${cache_dir}" ]]; then
	fail "Cache directory not found: ${cache_dir}"
	exit 1
fi

# Find all .done files in cache (bash 3.2+ compatible)
done_files=()
while IFS= read -r file; do
	done_files+=("${file}")
done < <(find "${cache_dir}" -type f -name "*.done" -exec basename {} \; | sort)

if [[ "${#done_files[@]}" -eq 0 ]]; then
	info "No installations found in cache"
	exit 0
fi

info "Found ${#done_files[@]} installed packages to upgrade"
plain ""

failed=()
succeeded=()

for done_file in "${done_files[@]}"; do
	# Extract the base name without .done extension
	install_name="${done_file%.done}"

	# Look for exact match installer scripts (auto or manual)
	installer=""
	if [[ -f "${script_dir}/${install_name}.auto.bash" ]]; then
		installer="${script_dir}/${install_name}.auto.bash"
	elif [[ -f "${script_dir}/${install_name}.manual.bash" ]]; then
		installer="${script_dir}/${install_name}.manual.bash"
	elif [[ -f "${script_dir}/${install_name}.manual.install" ]]; then
		installer="${script_dir}/${install_name}.manual.install"
	fi

	if [[ -z "${installer}" ]]; then
		warn "No installer found for: ${install_name}"
		failed+=("${install_name} (no installer found)")
		continue
	fi

	info "Upgrading: ${install_name}"
	if "${installer}" --force; then
		succeeded+=("${install_name}")
	else
		failed+=("${install_name}")
	fi
	break
	plain ""
done

plain "============================================"
plain "Upgrade Summary"
plain "============================================"
plain "Succeeded: ${#succeeded[@]}"
for pkg in "${succeeded[@]}"; do
	pass "${pkg}"
done
plain ""

if [[ "${#failed[@]}" -gt 0 ]]; then
	plain "Failed: ${#failed[@]}"
	for pkg in "${failed[@]}"; do
		fail "${pkg}"
	done
	exit 1
fi
