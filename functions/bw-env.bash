alias bw-env=bw_env
bw_env () {
local STATUS FOLDER_ID LINE

if [[ -z "${MY_PROFILE}" ]]; then
	>&2 echo ":: MY_PROFILE is not set"
	return 1
fi

# TODO: This is currently duplciated from profile.bash
if [[ "$(uname -s)" == 'Darwin' ]]; then
	>&2 echo ":: login"
	bw login --check &> /dev/null || BW_SESSION="bw login --apikey --raw"
	>&2 echo ":: unlock"
	bw unlock --check &> /dev/null || BW_SESSION="$(bw unlock --raw)"
	if [[ -z "${BW_SESSION}" ]]; then
		>&2 echo ":: BW_SESSION missing"
		return 1
	fi
	export BW_SESSION
	bw sync
else
	if ! KEY_ID="$(keyctl request user bw_session 2> /dev/null)"; then
		>&2 echo ":: login"
		bw login --check &> /dev/null || BW_SESSION="bw login --apikey --raw"
		>&2 echo ":: unlock"
		bw unlock --check &> /dev/null || BW_SESSION="$(bw unlock --raw)"
		if [[ -z "${BW_SESSION}" ]]; then
			>&2 echo ":: BW_SESSION missing"
			return 1
		fi
		KEY_ID=$(echo "${BW_SESSION}" | keyctl padd user bw_session @u)
	else
		>&2 echo ":: using keychain"
		BW_SESSION="$(keyctl pipe "${KEY_ID}")"
	fi
	keyctl timeout "${KEY_ID}" ${AUTO_LOCK:-900}
	export BW_SESSION
	bw sync
fi

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
QUERY=$(\cat <<- DOC
# loop through the items
map(
	# ignore any item w/o .fields
	select(.fields)
	# create a new object with .id and .name
	| {id: .id, name: .name}
	# combine it with the array of fields turned into key/values
		+ (
				.fields | from_entries
			)
	# only use type=env objects
	| select(.type == "env")
	# match the name based on all passed in arguments
	| select(.name == "$@")
	# delete any of the non-env var fields
	| del(.type, .id, .name)
)
# take only the objects from the array
| .[]
# turn the object into an array of key:value objects
| to_entries
# create a string usable in an "export" command
| map("\(.key)=\(.value)")[]
DOC
)
while IFS=$'\n\t' read -r LINE; do
	echo "${LINE%%=*}"
	export "${LINE}"
done <<< "$( \
	bw list items \
	--folderid "${FOLDER_ID}" \
	| jq -rM --from-file <(echo "${QUERY}")
)"
}
