alias color-theme=color_theme
color_theme() {
  # Switch the terminal and Vim color theme, persisting the selection for new sessions.
  local theme="${1:-}"
  local config_dir="${HOME}/.config/env-ubuntu"
  local config_file="${config_dir}/color-theme"
  local palette

  case "${theme}" in
    default)
      palette="${HOME}/.config/base16-shell/base16-default.dark.sh"
      ;;
    remarkable)
      palette="${HOME}/.config/base16-shell/base16-remarkable.light.sh"
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

  mkdir -p "${config_dir}" || return 1
  printf '%s\n' "${theme}" > "${config_file}" || return 1

  # shellcheck disable=SC1090
  source "${palette}"
  printf 'Color theme set to %s. Restart Vim to apply its matching palette.\n' "${theme}"
}
