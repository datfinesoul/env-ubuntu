alias color-theme=color_theme
color_theme() {
  # Switch the terminal and Vim color theme, persisting the selection for new sessions.
  local theme="${1:-}"
  local config_dir="${HOME}/.config/env-ubuntu"
  local config_file="${config_dir}/color-theme"
  local palette
  local pi_theme
  local repo_root="${ENV_UBUNTU_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  local pi_theme_dir="${HOME}/.pi/agent/themes"
  local pi_settings_dir="${HOME}/.pi/agent"
  local pi_settings_file="${pi_settings_dir}/settings.json"
  local pi_settings_tmp="${TMPDIR:-/tmp}/env-ubuntu-pi-settings.$$"
  local kitty_theme
  local kitty_theme_file="${config_dir}/kitty-theme.conf"
  local git_theme
  local git_theme_file="${config_dir}/git-theme.gitconfig"
  local bat_theme
  local btop_theme
  local btop_theme_name
  local btop_theme_dir="${HOME}/.config/btop/themes"
  local btop_config_file="${HOME}/.config/btop/btop.conf"
  local btop_config_tmp="${TMPDIR:-/tmp}/env-ubuntu-btop.$$"
  local btop_note=""

  case "${theme}" in
    default)
      palette="${HOME}/.config/base16-shell/base16-default.dark.sh"
      pi_theme="dark"
      kitty_theme="${repo_root}/themes/kitty/default.conf"
      git_theme="${repo_root}/themes/git/default.gitconfig"
      bat_theme="1337"
      btop_theme="${repo_root}/themes/btop/default.theme"
      btop_theme_name="env-ubuntu-default"
      ;;
    remarkable)
      palette="${HOME}/.config/base16-shell/base16-remarkable.light.sh"
      pi_theme="remarkable"
      kitty_theme="${repo_root}/themes/kitty/remarkable.conf"
      git_theme="${repo_root}/themes/git/remarkable.gitconfig"
      bat_theme="ansi"
      btop_theme="${repo_root}/themes/btop/remarkable.theme"
      btop_theme_name="env-ubuntu-remarkable"
      ;;
    *)
      printf 'usage: color-theme {default|remarkable}\n' >&2
      return 2
      ;;
  esac

  if [[ ! -r "${palette}" ]]; then
    printf 'color-theme: palette not found: %s\n' "${palette}" >&2
    return 1
  fi
  if [[ ! -r "${pi_theme_dir}/remarkable.json" ]]; then
    printf 'color-theme: Pi theme not found: %s\n' "${pi_theme_dir}/remarkable.json" >&2
    return 1
  fi
  if [[ ! -r "${kitty_theme}" ]]; then
    printf 'color-theme: Kitty theme not found: %s\n' "${kitty_theme}" >&2
    return 1
  fi
  if [[ ! -r "${git_theme}" ]]; then
    printf 'color-theme: Git theme not found: %s\n' "${git_theme}" >&2
    return 1
  fi
  if command -v btop > /dev/null 2>&1 && [[ ! -r "${btop_theme}" ]]; then
    printf 'color-theme: btop theme not found: %s\n' "${btop_theme}" >&2
    return 1
  fi
  if ! command -v jq > /dev/null 2>&1; then
    printf 'color-theme: jq is required to update Pi settings\n' >&2
    return 1
  fi

  mkdir -p "${config_dir}" "${pi_settings_dir}" || return 1
  [[ -s "${pi_settings_file}" ]] || printf '{}\n' > "${pi_settings_file}" || return 1

  if ! jq --arg theme "${pi_theme}" '.theme = $theme | del(.themes)' \
    "${pi_settings_file}" > "${pi_settings_tmp}"; then
    rm -f "${pi_settings_tmp}"
    printf 'color-theme: could not update Pi settings: %s\n' "${pi_settings_file}" >&2
    return 1
  fi
  cat "${pi_settings_tmp}" > "${pi_settings_file}" || return 1
  rm -f "${pi_settings_tmp}"
  cp "${kitty_theme}" "${kitty_theme_file}" || return 1
  cp "${git_theme}" "${git_theme_file}" || return 1
  if command -v btop > /dev/null 2>&1; then
    mkdir -p "${btop_theme_dir}" || return 1
    cp "${btop_theme}" "${btop_theme_dir}/${btop_theme_name}.theme" || return 1
    if [[ -f "${btop_config_file}" ]]; then
      # btop rewrites its config, so edit the live file instead of linking it.
      if ! awk -v value="${btop_theme_name}" '
        /^color_theme[[:space:]]*=/ { print "color_theme = \"" value "\""; found = 1; next }
        { print }
        END { if (!found) print "color_theme = \"" value "\"" }
      ' "${btop_config_file}" > "${btop_config_tmp}"; then
        rm -f "${btop_config_tmp}"
        printf 'color-theme: could not update btop settings: %s\n' "${btop_config_file}" >&2
        return 1
      fi
      mv "${btop_config_tmp}" "${btop_config_file}" || return 1
    else
      mkdir -p "$(dirname "${btop_config_file}")" || return 1
      printf 'color_theme = "%s"\n' "${btop_theme_name}" > "${btop_config_file}" || return 1
    fi
    btop_note="${btop_theme_name}"
  fi
  printf '%s\n' "${theme}" > "${config_file}" || return 1

  # shellcheck disable=SC1090
  source "${palette}"
  export BAT_THEME="${bat_theme}"
  printf 'Color theme set to %s (Pi: %s, bat: %s, Git delta updated). Restart Vim, Pi, and Kitty to apply it everywhere.\n' \
    "${theme}" "${pi_theme}" "${bat_theme}"
  if [[ -n "${btop_note}" ]]; then
    printf 'btop theme %s installed; restart btop to apply it.\n' "${btop_note}"
  fi
}
