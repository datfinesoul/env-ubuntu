#!/bin/sh
# Base16 reMarkable - Shell color setup script
# Warm monochrome palette inspired by a reMarkable e-ink display

if [ "${TERM%%-*}" = 'linux' ]; then
    # This script doesn't support linux console (use 'vconsole' template instead)
    return 2>/dev/null || exit 0
fi

color00="1f/20/1e" # Base 00 - Black
color01="9c/3d/34" # Base 08 - Red
color02="37/77/48" # Base 0B - Green
color03="95/66/00" # Base 0A - Yellow
color04="32/65/91" # Base 0D - Blue
color05="79/49/82" # Base 0E - Magenta
color06="00/6f/76" # Base 0C - Cyan
color07="68/69/64" # Base 05 - White
color08="8a/8b/85" # Base 03 - Bright Black
color09="bd/40/34" # Base 08 - Bright Red
color10="35/90/50" # Base 0B - Bright Green
color11="b5/7d/00" # Base 0A - Bright Yellow
color12="2d/7f/b6" # Base 0D - Bright Blue
color13="95/52/a2" # Base 0E - Bright Magenta
color14="00/87/90" # Base 0C - Bright Cyan
color15="3d/3e/3a" # Base 07 - Bright White
color16="aa/60/25" # Base 09
color17="78/47/3d" # Base 0F
color18="d8/d6/cf" # Base 01
color19="c5/c4/bd" # Base 02
color20="77/78/73" # Base 04
color21="f2/f0/e9" # Base 06
color_foreground="29/2a/28" # Base 02
color_background="e3/e1/da" # Base 07
color_cursor="29/2a/28" # Base 02

if [ -n "$TMUX" ]; then
  # tell tmux to pass the escape sequences through
  printf_template="\033Ptmux;\033\033]4;%d;rgb:%s\007\033\\"
  printf_template_var="\033Ptmux;\033\033]%d;rgb:%s\007\033\\"
  printf_template_custom="\033Ptmux;\033\033]%s%s\007\033\\"
elif [ "${TERM%%-*}" = "screen" ]; then
  printf_template="\033P\033]4;%d;rgb:%s\007\033\\"
  printf_template_var="\033P\033]%d;rgb:%s\007\033\\"
  printf_template_custom="\033P\033]%s%s\007\033\\"
else
  printf_template="\033]4;%d;rgb:%s\033\\"
  printf_template_var="\033]%d;rgb:%s\033\\"
  printf_template_custom="\033]%s%s\033\\"
fi

# 16 color space
printf $printf_template 0  $color00
printf $printf_template 1  $color01
printf $printf_template 2  $color02
printf $printf_template 3  $color03
printf $printf_template 4  $color04
printf $printf_template 5  $color05
printf $printf_template 6  $color06
printf $printf_template 7  $color07
printf $printf_template 8  $color08
printf $printf_template 9  $color09
printf $printf_template 10 $color10
printf $printf_template 11 $color11
printf $printf_template 12 $color12
printf $printf_template 13 $color13
printf $printf_template 14 $color14
printf $printf_template 15 $color15

# 256 color space
printf $printf_template 16 $color16
printf $printf_template 17 $color17
printf $printf_template 18 $color18
printf $printf_template 19 $color19
printf $printf_template 20 $color20
printf $printf_template 21 $color21

# foreground / background / cursor color
if [ -n "$ITERM_SESSION_ID" ]; then
  # iTerm2 proprietary escape codes
  printf $printf_template_custom Pg 292a28 # foreground
  printf $printf_template_custom Ph e3e1da # background
  printf $printf_template_custom Pi 1f201e # bold color
  printf $printf_template_custom Pj c5c4bd # selection color
  printf $printf_template_custom Pk 292a28 # selected text color
  printf $printf_template_custom Pl 292a28 # cursor
  printf $printf_template_custom Pm e3e1da # cursor text
else
  printf $printf_template_var 10 $color_foreground
  printf $printf_template_var 11 $color_background
  printf $printf_template_var 12 $color_cursor
fi

# clean up
unset printf_template
unset printf_template_var
unset printf_template_custom
unset color00
unset color01
unset color02
unset color03
unset color04
unset color05
unset color06
unset color07
unset color08
unset color09
unset color10
unset color11
unset color12
unset color13
unset color14
unset color15
unset color16
unset color17
unset color18
unset color19
unset color20
unset color21
unset color_foreground
unset color_background
unset color_cursor
