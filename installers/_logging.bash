#!/usr/bin/env bash

supports_color() {
	# Manual override
	[ -n "${FORCE_COLOR:-}" ] && return 0
	# Common truecolor indicators
	[[ "${COLORTERM:-}" =~ (truecolor|24bit) ]] && return 0
	# TERM matches common color-capable terminals
	[[ "$TERM" =~ (xterm|screen|tmux|rxvt|linux|vt100|color) ]] && return 0
	# Check if stderr is a terminal (since our logging goes to stderr)
	[ -t 2 ] && return 0
	# Fallback: attempt basic ANSI color escape and check if terminal interprets it
	printf '\033[31m' >&2 && [ $? -eq 0 ] && return 0
	return 1
}
supports_color && enable_color=true || enable_color=false
red="${enable_color:+$(tput setaf 1)}"
green="${enable_color:+$(tput setaf 2)}"
yellow="${enable_color:+$(tput setaf 3)}"
cyan="${enable_color:+$(tput setaf 6)}"
white="${enable_color:+$(tput setaf 7)}"
gray="${enable_color:+$(tput dim)$(tput setaf 7)}"
magenta="${enable_color:+$(tput setaf 5)}"
reset="${enable_color:+$(tput sgr0)}"

# Need to save stderr to fd3, since it's redirected globally later
exec 3>&2

custom_log() {
	local prefix="$1"
	local postfix="$2"
	shift 2
	if [[ -p /dev/stdin && "$#" -eq 0 ]]; then
		while IFS= read -r line || [ -n "$line" ]; do
			>&3 echo -e "${prefix}${line}${postfix}"
		done
	else
		>&3 echo -e "${prefix}$*${postfix}"
	fi
}
plain() { custom_log "" "" "$@"; }
info() { custom_log "[i] " "" "$@"; }
debug() { custom_log "[${gray}D${reset}]${gray} " "${reset}" "$@"; }
pass() { custom_log "[${green}✔${reset}]${green} " "${reset}" "$@"; }
warn() { custom_log "[${magenta}!${reset}]${magenta} " "${reset}" "$@"; }
fail() { custom_log "[${red}✘${reset}]${red} " "${reset}" "$@"; }
yesno() {
	info "$@"
	>&2 read -r -p "[?] [yes/no]: " yn
}
