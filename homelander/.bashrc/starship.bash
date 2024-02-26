if [[ -z "${BASH_VERSINFO[0]}" || "${BASH_VERSINFO[0]}" -lt 4 ]]; then
	source /dev/stdin <<<"$("$(which starship)" init bash --print-full-init)"
else
	eval "$(starship init bash)"
fi
