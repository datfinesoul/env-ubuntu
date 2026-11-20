#!/usr/bin/env bash
# Tests for machine.bash: identity precedence and profile listing.
#
# shellcheck source=./lib.bash
. "$(dirname "${0}")/lib.bash"

use_temp_home
unset ENV_UBUNTU_MACHINE

# Runs a snippet with _core.bash and machine.bash sourced from the repo, so
# script_dir resolves to the repository root.
probe() {
	bash -s 2>/dev/null <<EOF
cd "${REPO_ROOT}" || exit 1
source ./_core.bash
source ./machine.bash
$1
EOF
}

# 1. An explicit name wins over the environment.
check_equal "explicit name wins" "explicit-name" \
	"$(ENV_UBUNTU_MACHINE=env-name probe "resolve_machine explicit-name")"

# 2. ENV_UBUNTU_MACHINE is used when no name is passed.
check_equal "environment name used" "env-name" \
	"$(ENV_UBUNTU_MACHINE=env-name probe "resolve_machine")"

# 3. The local record is used when no name and no environment exist.
mkdir -p "${HOME}/.config/env-ubuntu"
printf 'record-name\n' > "${HOME}/.config/env-ubuntu/machine"
check_equal "record name used" "record-name" "$(probe "resolve_machine")"

# 4. Nothing selected resolves to an empty name.
rm -f "${HOME}/.config/env-ubuntu/machine"
check_equal "empty without a selection" "" "$(probe "resolve_machine")"

# 5. Profile listing reads a directory of profiles and sorts the names.
work="$(new_temp_dir)"
mkdir -p "${work}/profiles/b" "${work}/profiles/a"
printf 'ignored\n' > "${work}/profiles/stray.txt"
export FIXTURE_ROOT="${work}/profiles"
check_equal "profiles are listed and sorted" "a
b" "$(probe "available_machines \"\${FIXTURE_ROOT}\"")"

# 6. require_machine returns an explicit name without prompting.
check_equal "require_machine returns an explicit name" "explicit-name" \
	"$(ENV_UBUNTU_MACHINE=env-name probe "require_machine explicit-name")"

finish
