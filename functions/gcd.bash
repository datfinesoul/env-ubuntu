gcd() {
  local TARGET
  TARGET="${1}"

  # if not in a git repo, print an error and exit
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a Git repository."; return 1; }

  # Handle absolute and relative paths
  if [[ "${TARGET}" == /* ]]; then
    cd "${TARGET}" || { echo "Failed to change directory to '${TARGET}'"; return 1; }
  else
    cd "${repo_root}/${TARGET}" || { echo "Failed to change directory to '${repo_root}/${TARGET}'"; return 1; }
  fi
}

_gcd_completions() {
	log_debug "-------"
  # if not in a git repo, exit
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return

  local suggestions search relative_path current_input depth find_root difference final
  current_input="${repo_root}/${COMP_WORDS[1]}"
	log_debug "ci:$current_input"
	find_root="${current_input%/*}"
	log_debug "fr:$find_root"
	current_input="${current_input/${find_root}/}"
	current_input="${current_input#/}"
	#if [[ -z "$current_input" ]]; then
	#  log_debug "ciz"
	#  current_input="${find_root/${repo_root}}"
	#  current_input="${current_input#/}/"
	#fi
	log_debug "ci2:$current_input"

	difference="${find_root/${repo_root}}"
	difference="${difference#/}/"
	log_debug "dif:$difference"
	depth=$(echo "${difference}" | tr -cd '/' | wc -c)
	if [[ "$difference" == "/" ]]; then
		depth=1
		difference=""
	else
		depth=$(( depth + 1))
	fi
	log_debug "d:$depth"
	search=$(find "${repo_root}" -maxdepth $depth -mindepth 1 -type d \
		-not -name "." -not -name ".." -not -name ".git" \
		-path "${find_root}/${current_input}*" \
		2>/dev/null)
	log_debug "s:\n$search"
  suggestions=()
  for path in $search; do
    relative_path="${path#$find_root/}"
    suggestions+=("$relative_path")
  done

	log_debug "#:${#suggestions[@]}"
	if [[ "${#suggestions[@]}" -eq 0 ]]; then
		true
	elif [[ "${#suggestions[@]}" -eq 1 ]]; then
		log_debug "s[0]:'${suggestions[0]}'"
		if [[ "$find_root" == "${suggestions[0]}" ]]; then
			COMPREPLY=("${current_input}/")
		elif [[ -z "$current_input" ]]; then
			COMPREPLY=("${current_input}")
		else
			COMPREPLY="${difference}${suggestions[0]}"
		fi
		log_debug "cr:'${COMPREPLY[*]}'"
	else
		COMPREPLY=("${suggestions[@]}")
	fi
}

complete -F _gcd_completions -o nospace gcd
