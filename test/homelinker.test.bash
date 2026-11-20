#!/usr/bin/env bash
# Tests for homelinker.bash: shared links, machine overlay, materialization.
#
# shellcheck source=./lib.bash
. "$(dirname "${0}")/lib.bash"

homelinker="${REPO_ROOT}/homelinker.bash"
unset ENV_UBUNTU_MACHINE

setup_fixtures() {
	local root="$1"
	mkdir -p "${root}/base/.config/kitty"
	mkdir -p "${root}/machine/.config/kitty"
	printf 'shared-vimrc\n' > "${root}/base/.vimrc"
	printf 'shared\n' > "${root}/base/.my_profiles.json"
	printf 'shared-kitty\n' > "${root}/base/.config/kitty/kitty.conf"
	printf 'machine\n' > "${root}/machine/.my_profiles.json"
	printf 'machine-extra\n' > "${root}/machine/.config/kitty/extra.conf"
}

use_temp_home

# 1. Shared files are linked and top-level directories are materialized.
work="$(new_temp_dir)"
setup_fixtures "${work}"
"${homelinker}" --source "${work}/base" --target "${work}/home-1" > "${work}/log-1" 2>&1
check_symlink "shared file linked" "${work}/home-1/.vimrc"
check_equal "shared file points at source" "${work}/base/.vimrc" "$(readlink "${work}/home-1/.vimrc")"
check_plain_dir "top-level directory materialized" "${work}/home-1/.config"
check_symlink "nested directory linked whole" "${work}/home-1/.config/kitty"
check_equal "nested directory points at source" "${work}/base/.config/kitty" "$(readlink "${work}/home-1/.config/kitty")"
check_equal "no machine overlay without a profile" "${work}/base/.my_profiles.json" "$(readlink "${work}/home-1/.my_profiles.json")"

# 2. A machine overlay replaces the shared link for the same path.
"${homelinker}" --source "${work}/base" --target "${work}/home-2" --machine-dir "${work}/machine" > "${work}/log-2" 2>&1
check_equal "machine overlay wins over shared link" \
	"${work}/machine/.my_profiles.json" \
	"$(readlink "${work}/home-2/.my_profiles.json")"

# 3. A machine entry inside a shared directory materializes the directory.
check_plain_dir "shared directory materialized for the overlay" "${work}/home-2/.config/kitty"
check_equal "shared child still linked" \
	"${work}/base/.config/kitty/kitty.conf" \
	"$(readlink "${work}/home-2/.config/kitty/kitty.conf")"
check_equal "machine child linked beside the shared child" \
	"${work}/machine/.config/kitty/extra.conf" \
	"$(readlink "${work}/home-2/.config/kitty/extra.conf")"

# 4. A local regular file is preserved and reported.
mkdir -p "${work}/home-4"
printf 'local-vimrc\n' > "${work}/home-4/.vimrc"
"${homelinker}" --source "${work}/base" --target "${work}/home-4" > "${work}/log-4" 2>&1
check_not_symlink "local file preserved" "${work}/home-4/.vimrc"
check_equal "local file content unchanged" "local-vimrc" "$(cat "${work}/home-4/.vimrc")"
check_contains "local file reported" "skip" "$(cat "${work}/log-4")"

# 5. The recorded machine selects the overlay without arguments.
mkdir -p "${HOME}/.config/env-ubuntu"
printf 'dell-laptop-linux\n' > "${HOME}/.config/env-ubuntu/machine"
"${homelinker}" --source "${work}/base" --target "${work}/home-5" > "${work}/log-5" 2>&1
check_equal "machine record selects the repository overlay" \
	"${REPO_ROOT}/homelander/_machines/dell-laptop-linux/_home/.my_profiles.json" \
	"$(readlink "${work}/home-5/.my_profiles.json")"

# 6. A missing shared tree fails.
if "${homelinker}" --source "${work}/missing" --target "${work}/home-6" > "${work}/log-6" 2>&1; then
	check_equal "missing shared tree rejected" "nonzero exit" "zero exit"
else
	check_equal "missing shared tree rejected" "nonzero exit" "nonzero exit"
fi
check_contains "missing shared tree reported" "shared tree not found" "$(cat "${work}/log-6")"

# 7. An explicit missing machine overlay fails.
if "${homelinker}" --source "${work}/base" --target "${work}/home-7" --machine-dir "${work}/nope" > "${work}/log-7" 2>&1; then
	check_equal "missing overlay rejected" "nonzero exit" "zero exit"
else
	check_equal "missing overlay rejected" "nonzero exit" "nonzero exit"
fi
check_contains "missing overlay reported" "machine overlay not found" "$(cat "${work}/log-7")"

finish
