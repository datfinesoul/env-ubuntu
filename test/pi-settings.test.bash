#!/usr/bin/env bash
# Tests for pi-settings.bash: machine resolution, render output, and safety.
#
# shellcheck source=./lib.bash
. "$(dirname "${0}")/lib.bash"

pi_settings="${REPO_ROOT}/pi-settings.bash"
machine_name="dell-laptop-linux"

seed_target() {
	local file="${HOME}/.pi/agent/settings.json"
	mkdir -p "$(dirname "${file}")"
	printf '{"theme":"remarkable","lastChangelogVersion":"1.5.2","extensionChangelogVersions":{"x":"1"}}\n' > "${file}"
}

# 1. ENV_UBUNTU_MACHINE selects the profile and the render keeps local keys.
use_temp_home
seed_target
ENV_UBUNTU_MACHINE="${machine_name}" "${pi_settings}" > "${HOME}/run-1.log" 2>&1
check_equal "machine from env var renders" "opencode-go" "$(jq -r '.defaultProvider' "${HOME}/.pi/agent/settings.json")"
check_equal "shared key from base renders" "fullscreen" "$(jq -r '.tuiMode' "${HOME}/.pi/agent/settings.json")"
check_equal "runtime key survives" "1.5.2" "$(jq -r '.lastChangelogVersion' "${HOME}/.pi/agent/settings.json")"
check_equal "extension runtime key survives" "1" "$(jq -r '.extensionChangelogVersions.x' "${HOME}/.pi/agent/settings.json")"
check_equal "local theme survives" "remarkable" "$(jq -r '.theme' "${HOME}/.pi/agent/settings.json")"
check_equal "machine recorded" "${machine_name}" "$(cat "${HOME}/.config/env-ubuntu/machine")"

# 2. The recorded machine is used when no override is set.
use_temp_home
seed_target
mkdir -p "${HOME}/.config/env-ubuntu"
printf '%s\n' "${machine_name}" > "${HOME}/.config/env-ubuntu/machine"
"${pi_settings}" > "${HOME}/run-2.log" 2>&1
check_equal "machine from local record renders" "opencode-go" "$(jq -r '.defaultProvider' "${HOME}/.pi/agent/settings.json")"

# 3. No profile and no record fails with a profile list.
use_temp_home
if "${pi_settings}" > "${HOME}/run-3.log" 2>&1; then
	check_equal "missing machine is rejected" "nonzero exit" "zero exit"
else
	check_equal "missing machine is rejected" "nonzero exit" "nonzero exit"
fi
check_contains "missing machine lists profiles" "${machine_name}" "$(cat "${HOME}/run-3.log")"
check_file_absent "missing machine writes no target" "${HOME}/.pi/agent/settings.json"

# 4. An unknown profile name fails with a profile list.
use_temp_home
if "${pi_settings}" --machine nope > "${HOME}/run-4.log" 2>&1; then
	check_equal "unknown machine is rejected" "nonzero exit" "zero exit"
else
	check_equal "unknown machine is rejected" "nonzero exit" "nonzero exit"
fi
check_contains "unknown machine reported" "unknown machine profile" "$(cat "${HOME}/run-4.log")"
check_contains "unknown machine lists profiles" "${machine_name}" "$(cat "${HOME}/run-4.log")"

# 5. --machine beats ENV_UBUNTU_MACHINE.
use_temp_home
seed_target
ENV_UBUNTU_MACHINE="wrong-name" "${pi_settings}" --machine "${machine_name}" > "${HOME}/run-5.log" 2>&1
check_equal "argument beats env var" "${machine_name}" "$(cat "${HOME}/.config/env-ubuntu/machine")"

# 6. --dry-run changes nothing.
use_temp_home
"${pi_settings}" --machine "${machine_name}" --dry-run > "${HOME}/run-6.log" 2>&1
check_file_absent "dry-run writes no target" "${HOME}/.pi/agent/settings.json"
check_file_absent "dry-run writes no record" "${HOME}/.config/env-ubuntu/machine"
check_contains "dry-run reports the plan" "would render" "$(cat "${HOME}/run-6.log")"

# 7. A second run does not rewrite the target.
use_temp_home
seed_target
"${pi_settings}" --machine "${machine_name}" > "${HOME}/run-7a.log" 2>&1
before_sum="$(sha256sum "${HOME}/.pi/agent/settings.json" | cut -d' ' -f1)"
before_mtime="$(stat -c '%Y' "${HOME}/.pi/agent/settings.json" 2>/dev/null || stat -f '%m' "${HOME}/.pi/agent/settings.json")"
sleep 1
"${pi_settings}" --machine "${machine_name}" > "${HOME}/run-7b.log" 2>&1
after_sum="$(sha256sum "${HOME}/.pi/agent/settings.json" | cut -d' ' -f1)"
after_mtime="$(stat -c '%Y' "${HOME}/.pi/agent/settings.json" 2>/dev/null || stat -f '%m' "${HOME}/.pi/agent/settings.json")"
check_equal "second run keeps content" "${before_sum}" "${after_sum}"
check_equal "second run does not rewrite" "${before_mtime}" "${after_mtime}"

finish
