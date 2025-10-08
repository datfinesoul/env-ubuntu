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

  compopt -o filenames

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
    relative_path="${path#$repo_root/}"
    suggestions+=("$relative_path")
  done

	log_debug "#:${#suggestions[@]}"
	if [[ "${#suggestions[@]}" -eq 0 ]]; then
		true
	else
		log_debug "using compgen with current word: '${COMP_WORDS[1]}'"
		COMPREPLY=($(compgen -W "${suggestions[*]}" -- "${COMP_WORDS[1]}"))
		log_debug "cr:'${COMPREPLY[*]}'"
	fi
}

complete -F _gcd_completions -o nospace gcd
