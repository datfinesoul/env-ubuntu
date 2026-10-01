COLOR_THEME_FILE="$HOME/.config/env-ubuntu/color-theme"
COLOR_THEME="$(head -n 1 "$COLOR_THEME_FILE" 2> /dev/null || printf 'default')"
case "$COLOR_THEME" in
  remarkable) BASE16_SHELL="$HOME/.config/base16-shell/base16-remarkable.light.sh" ;;
  *) BASE16_SHELL="$HOME/.config/base16-shell/base16-default.dark.sh" ;;
esac
# shellcheck disable=SC1090
[[ -s $BASE16_SHELL ]] && source "$BASE16_SHELL"
unset BASE16_SHELL COLOR_THEME COLOR_THEME_FILE
