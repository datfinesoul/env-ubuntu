#!/usr/bin/env bash
# Tests for filtering failed commands from interactive Bash history.

# shellcheck source=./lib.bash
. "$(dirname "${0}")/lib.bash"

work="$(mktemp -d)"
cleanup_paths+=("${work}")
export HOME="${work}/home"
mkdir -p "${HOME}"
unset PROMPT_COMMAND
export HISTORY_SNIPPET="${REPO_ROOT}/homelander/.bashrc/bash-history.bash"
export HISTFILE="${HOME}/.bash_history"
touch "${HOME}/marker"

cat > "${HOME}/test.bashrc" <<'BASH'
nvmrc() { printf 'prompt status: %s\n' "$?"; }
PROMPT_COMMAND=nvmrc
source "$HISTORY_SNIPPET"
BASH

output="$(bash --noprofile --rcfile "${HOME}/test.bashrc" -i 2>/dev/null <<'BASH'
[ -e "$HOME/marker" ]
rm "$HOME/marker"
[ -e "$HOME/marker" ]
printf 'next command status: %s\n' "$?"
 false
false
nonexistent_history_test_command
true
true
 exit 0
BASH
)"

expected="$(cat <<'HISTORY'
[ -e "$HOME/marker" ]
rm "$HOME/marker"
printf 'next command status: %s\n' "$?"
true
HISTORY
)"
actual="$(grep -v '^#[0-9][0-9]*$' "${HISTFILE}")"
check_equal 'save only successful history entries' "${expected}" "${actual}"
check_contains 'existing prompt hook sees failure status' 'prompt status: 1' "${output}"
check_contains 'next command sees failure status' 'next command status: 1' "${output}"

finish
