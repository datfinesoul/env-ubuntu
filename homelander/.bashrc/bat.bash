COLOR_THEME_FILE="$HOME/.config/env-ubuntu/color-theme"
COLOR_THEME="$(head -n 1 "$COLOR_THEME_FILE" 2> /dev/null || printf 'default')"
case "$COLOR_THEME" in
  remarkable) export BAT_THEME=ansi ;;
  *) export BAT_THEME=1337 ;;
esac
unset COLOR_THEME COLOR_THEME_FILE
