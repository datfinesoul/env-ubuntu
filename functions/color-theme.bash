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

  case "${theme}" in
    default)
      palette="${HOME}/.config/base16-shell/base16-default.dark.sh"
      pi_theme="dark"
      kitty_theme="${repo_root}/themes/kitty/default.conf"
      git_theme="${repo_root}/themes/git/default.gitconfig"
      bat_theme="1337"
      ;;
    remarkable)
      palette="${HOME}/.config/base16-shell/base16-remarkable.light.sh"
      pi_theme="remarkable"
      kitty_theme="${repo_root}/themes/kitty/remarkable.conf"
      git_theme="${repo_root}/themes/git/remarkable.gitconfig"
      bat_theme="ansi"
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
  printf '%s\n' "${theme}" > "${config_file}" || return 1

  # shellcheck disable=SC1090
  source "${palette}"
  export BAT_THEME="${bat_theme}"
  printf 'Color theme set to %s (Pi: %s, bat: %s, Git delta updated). Restart Vim, Pi, and Kitty to apply it everywhere.\n' \
    "${theme}" "${pi_theme}" "${bat_theme}"
}
