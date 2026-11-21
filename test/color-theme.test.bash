#!/usr/bin/env bash
# Tests for functions/color-theme.bash: file copies, Pi settings, and btop.
#
# shellcheck source=./lib.bash
. "$(dirname "${0}")/lib.bash"

export ENV_UBUNTU_ROOT="${REPO_ROOT}"
# The base16 palette reads these without defaults; define them for `set -u`.
export TMUX=""
export ITERM_SESSION_ID=""
# shellcheck source=../functions/color-theme.bash
. "${REPO_ROOT}/functions/color-theme.bash"

seed_home() {
	use_temp_home
	mkdir -p "${HOME}/.config/base16-shell" "${HOME}/.pi/agent/themes" "${HOME}/.config/btop"
	cp "${REPO_ROOT}/homelander/_home/.config/base16-shell/base16-remarkable.light.sh" \
		"${REPO_ROOT}/homelander/_home/.config/base16-shell/base16-default.dark.sh" \
		"${HOME}/.config/base16-shell/"
	cp "${REPO_ROOT}/homelander/_home/.pi/agent/themes/remarkable.json" \
		"${HOME}/.pi/agent/themes/"
	printf 'color_theme = "Default"\ntheme_background = True\ndelay = 15\n' \
		> "${HOME}/.config/btop/btop.conf"
}

# 1. remarkable installs every surface and selects the btop theme.
seed_home
color_theme remarkable > "${HOME}/run-1.log" 2>&1
check_equal "btop theme selected" 'color_theme = "env-ubuntu-remarkable"' \
	"$(grep '^color_theme' "${HOME}/.config/btop/btop.conf")"
check_equal "btop settings preserved" "theme_background = True" \
	"$(sed -n 2p "${HOME}/.config/btop/btop.conf")"
check_file_exists "btop theme installed" "${HOME}/.config/btop/themes/env-ubuntu-remarkable.theme"
check_equal "btop theme matches tracked file" \
	"$(cat "${REPO_ROOT}/themes/btop/remarkable.theme")" \
	"$(cat "${HOME}/.config/btop/themes/env-ubuntu-remarkable.theme")"
check_equal "kitty theme copied" "$(cat "${REPO_ROOT}/themes/kitty/remarkable.conf")" \
	"$(cat "${HOME}/.config/env-ubuntu/kitty-theme.conf")"
check_equal "git theme copied" "$(cat "${REPO_ROOT}/themes/git/remarkable.gitconfig")" \
	"$(cat "${HOME}/.config/env-ubuntu/git-theme.gitconfig")"
check_equal "selection recorded" "remarkable" "$(cat "${HOME}/.config/env-ubuntu/color-theme")"
check_equal "pi theme set" "remarkable" "$(jq -r '.theme' "${HOME}/.pi/agent/settings.json")"

# 2. default switches the btop theme back.
color_theme default > "${HOME}/run-2.log" 2>&1
check_equal "btop theme switches" 'color_theme = "env-ubuntu-default"' \
	"$(grep '^color_theme' "${HOME}/.config/btop/btop.conf")"
check_file_exists "default btop theme installed" "${HOME}/.config/btop/themes/env-ubuntu-default.theme"
check_equal "default selection recorded" "default" "$(cat "${HOME}/.config/env-ubuntu/color-theme")"
check_equal "default kitty theme copied" "$(cat "${REPO_ROOT}/themes/kitty/default.conf")" \
	"$(cat "${HOME}/.config/env-ubuntu/kitty-theme.conf")"

# 3. A missing btop.conf is created with the selected theme.
seed_home
rm -f "${HOME}/.config/btop/btop.conf"
color_theme remarkable > "${HOME}/run-3.log" 2>&1
check_file_exists "btop config created" "${HOME}/.config/btop/btop.conf"
check_equal "btop config selects theme" 'color_theme = "env-ubuntu-remarkable"' \
	"$(cat "${HOME}/.config/btop/btop.conf")"

# 4. Without btop on PATH nothing btop-related is written.
seed_home
fake_bin="$(new_temp_dir)/bin"
mkdir -p "${fake_bin}"
for command_name in jq awk cat cp mkdir mv rm dirname; do
	ln -s "$(command -v "${command_name}")" "${fake_bin}/${command_name}"
done
PATH="${fake_bin}" color_theme remarkable > "${HOME}/run-4.log" 2>&1
check_file_absent "no btop theme without btop" "${HOME}/.config/btop/themes/env-ubuntu-remarkable.theme"
check_equal "btop config untouched without btop" 'color_theme = "Default"' \
	"$(grep '^color_theme' "${HOME}/.config/btop/btop.conf")"

# 5. Unknown themes are rejected without writing state.
seed_home
if color_theme bogus > "${HOME}/run-5.log" 2>&1; then
	check_equal "unknown theme rejected" "nonzero exit" "zero exit"
else
	check_equal "unknown theme rejected" "nonzero exit" "nonzero exit"
fi
check_file_absent "unknown theme writes no selection" "${HOME}/.config/env-ubuntu/color-theme"

finish
