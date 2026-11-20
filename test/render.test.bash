#!/usr/bin/env bash
# Tests for render.bash: merge semantics, atomic write, and migration safety.
#
# shellcheck source=./lib.bash
. "$(dirname "${0}")/lib.bash"

render="${REPO_ROOT}/render.bash"
file_mode() {
	if [[ "$(uname -s)" == "Darwin" ]]; then
		stat -f '%Lp' -- "$1"
	else
		stat -c '%a' -- "$1"
	fi
}

work="$(new_temp_dir)"
mkdir -p "${work}/in"

# 1. A new target gets the deep merge of base and patch.
printf '{"shared":true,"nested":{"left":1}}\n' > "${work}/in/base.json"
printf '{"machine":"x","nested":{"right":2}}\n' > "${work}/in/patch.json"
"${render}" "${work}/in/base.json" "${work}/in/patch.json" "${work}/out/1.json" > /dev/null 2>&1
check_json_equal "renders a new target" \
	'{"machine":"x","nested":{"left":1,"right":2},"shared":true}' \
	"${work}/out/1.json"

# 2. An existing target keeps keys that neither base nor patch manages.
printf '{"runtime":{"version":"1.5.2"},"theme":"remarkable","nested":{"left":0,"extra":9}}\n' > "${work}/out/2.json"
printf '{"nested":{"left":1}}\n' > "${work}/in/base-2.json"
printf '{}\n' > "${work}/in/patch-2.json"
"${render}" "${work}/in/base-2.json" "${work}/in/patch-2.json" "${work}/out/2.json" > /dev/null 2>&1
check_json_equal "preserves unmanaged keys" \
	'{"nested":{"extra":9,"left":1},"runtime":{"version":"1.5.2"},"theme":"remarkable"}' \
	"${work}/out/2.json"

# 3. A managed key wins over the existing target value.
printf '{"model":"local"}\n' > "${work}/out/3.json"
printf '{"model":"shared"}\n' > "${work}/in/base-3.json"
printf '{"model":"machine"}\n' > "${work}/in/patch-3.json"
"${render}" "${work}/in/base-3.json" "${work}/in/patch-3.json" "${work}/out/3.json" > /dev/null 2>&1
check_equal "managed key from patch wins" "machine" "$(jq -r '.model' "${work}/out/3.json")"

# 4. Arrays replace, they do not merge.
printf '{"packages":["old","local"]}\n' > "${work}/out/4.json"
printf '{"packages":["a","b"]}\n' > "${work}/in/base-4.json"
printf '{}\n' > "${work}/in/patch-4.json"
"${render}" "${work}/in/base-4.json" "${work}/in/patch-4.json" "${work}/out/4.json" > /dev/null 2>&1
check_equal "arrays replace" '["a","b"]' "$(jq -c '.packages' "${work}/out/4.json")"

# 5. A second run changes nothing.
cp "${work}/out/4.json" "${work}/out/5.json"
before_sum="$(sha256sum "${work}/out/5.json" | cut -d' ' -f1)"
before_mtime="$(stat -c '%Y' "${work}/out/5.json" 2>/dev/null || stat -f '%m' "${work}/out/5.json")"
sleep 1
"${render}" "${work}/in/base-4.json" "${work}/in/patch-4.json" "${work}/out/5.json" > /dev/null 2>&1
after_sum="$(sha256sum "${work}/out/5.json" | cut -d' ' -f1)"
after_mtime="$(stat -c '%Y' "${work}/out/5.json" 2>/dev/null || stat -f '%m' "${work}/out/5.json")"
check_equal "second run keeps content" "${before_sum}" "${after_sum}"
check_equal "second run does not rewrite the file" "${before_mtime}" "${after_mtime}"

# 6. A symlink into the repository is replaced by a regular file.
mkdir -p "${work}/home-6"
ln -s "${REPO_ROOT}/homelander/_render/.pi/agent/settings.json" "${work}/home-6/target.json"
"${render}" "${work}/in/base.json" "${work}/in/patch.json" "${work}/home-6/target.json" > /dev/null 2>&1
check_not_symlink "repository symlink replaced" "${work}/home-6/target.json"
check_equal "reviewed symlink target rendered" "x" "$(jq -r '.machine' "${work}/home-6/target.json")"

# 7. A symlink that points outside the repository is preserved.
mkdir -p "${work}/home-7"
printf '[Unit]\n' > "${work}/outside.ini"
ln -s "${work}/outside.ini" "${work}/home-7/target.json"
if "${render}" "${work}/in/base.json" "${work}/in/patch.json" "${work}/home-7/target.json" > "${work}/out/7.log" 2>&1; then
	check_equal "outside symlink is rejected" "nonzero exit" "zero exit"
else
	check_equal "outside symlink is rejected" "nonzero exit" "nonzero exit"
fi
check_symlink "outside symlink preserved" "${work}/home-7/target.json"
check_contains "outside symlink reported" "points outside the repository" "$(cat "${work}/out/7.log")"

# 8. A missing base fails without writing the target.
if "${render}" "${work}/in/missing.json" "${work}/in/patch.json" "${work}/out/8.json" > "${work}/out/8.log" 2>&1; then
	check_equal "missing base is rejected" "nonzero exit" "zero exit"
else
	check_equal "missing base is rejected" "nonzero exit" "nonzero exit"
fi
check_file_absent "missing base writes nothing" "${work}/out/8.json"
check_contains "missing base reported" "cannot read base" "$(cat "${work}/out/8.log")"

# 9. Invalid patch JSON fails.
printf 'not json\n' > "${work}/in/bad-patch.json"
if "${render}" "${work}/in/base.json" "${work}/in/bad-patch.json" "${work}/out/9.json" > "${work}/out/9.log" 2>&1; then
	check_equal "invalid patch is rejected" "nonzero exit" "zero exit"
else
	check_equal "invalid patch is rejected" "nonzero exit" "nonzero exit"
fi
check_file_absent "invalid patch writes nothing" "${work}/out/9.json"

# 10. A new target gets mode 0600.
check_equal "new target mode is 600" "600" "$(file_mode "${work}/out/1.json")"

# 11. An existing target keeps its mode.
printf '{}\n' > "${work}/out/11.json"
chmod 644 "${work}/out/11.json"
"${render}" "${work}/in/base.json" "${work}/in/patch.json" "${work}/out/11.json" > /dev/null 2>&1
check_equal "existing target mode preserved" "644" "$(file_mode "${work}/out/11.json")"

finish
