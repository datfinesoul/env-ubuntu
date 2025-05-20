log_red="$(tput setaf 1)"
log_green="$(tput setaf 2)"
log_gray="$(tput dim)$(tput setaf 7)"
log_magenta="$(tput setaf 5)"
log_reset="$(tput sgr0)"
log_custom () {
	local prefix="$1"
	local postfix="$2"
	local log_tty="${LOG_TTY:-/dev/null}"
	shift 2
	if [[ -p /dev/stdin && "$#" -eq 0 ]]; then
		while IFS= read -r line || [ -n "$line" ]; do
			>$log_tty echo -e "${prefix}${line}${postfix}"
		done
	else
		>$log_tty echo -e "${prefix}$*${postfix}"
	fi
}
log_plain() { log_custom "" "" "$@"; }
log_info() { log_custom "[i] " "" "$@"; }
log_debug() { log_custom "[${log_gray}D${log_reset}]${log_gray} " "${log_reset}" "$@"; }
log_pass() { log_custom "[${log_green}✔${log_reset}]${log_green} " "${log_reset}" "$@"; }
log_warn() { log_custom "[${log_magenta}!${log_reset}]${log_magenta} " "${log_reset}" "$@"; }
log_fail() { log_custom "[${log_red}✘${log_reset}]${log_red} " "${log_reset}" "$@"; }
