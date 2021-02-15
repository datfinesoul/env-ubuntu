# vi: noet :
# noet because we need tabs for the heredoc
bw_env () {
local STATUS FOLDER_ID LINE

if [[ -z "${MY_PROFILE}" ]]; then
	>&2 echo ":: MY_PROFILE is not set"
	return 1
fi

# check if the profile is unlocked
STATUS=0; bw unlock --check > /dev/null 2>&1 || STATUS=$?
if [[ "${STATUS}" -ne 0 ]]; then
	>&2 echo ":: bitwarden profile is locked"
	return 1
fi

>&2 bw sync

# obtain folderid from bitwarden based on MY_PROFILE
FOLDER_ID="$( \
	bw get folder "profile-${MY_PROFILE}" \
	| jq -rM '.id' \
	)"

if [[ -z "${FOLDER_ID}" ]]; then
	>&2 echo ":: unable to obtain folderid from bitwarden"
	return 1
fi

# 1. if fields object exists
# 2. combine id and name with:
#    1. take the fields object
#    2. convert array of fields into object with fields
#    3. pick only type = "env" and name = "<input>"
#    4. delete undesired fields
# 3. create a list of key=value strings export
while IFS=$'\n\t' read -r LINE; do
	export "${LINE}"
done < <(bw list items \
	--folderid "${FOLDER_ID}" \
	| jq -rM --from-file <(cat <<- DOC
		map(
			select(.fields)
			| {id: .id, name: .name}
				+ (
						.fields | from_entries
					)
			| select(.type == "env")
			| select(.name == "$@")
			| del(.type, .id, .name)
		)
		| .[]
		| to_entries
		| map("\(.key)=\"\(.value)\"")[]
DOC
))
}
