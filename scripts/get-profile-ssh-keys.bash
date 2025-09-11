#!/usr/bin/env bash
# vi: noet :

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# check if the profile is unlocked
STATUS=0; bw unlock --check > /dev/null 2>&1 || STATUS=$?
if [[ "${STATUS}" -ne 0 ]]; then
	>&2 echo ":: bitwarden profile is locked"
	exit 1
fi

bw sync

# obtain folderid from bitwarden based on MY_PROFILE
FOLDER_ID="$( \
	bw get folder "profile-${MY_PROFILE}" \
	| jq -rM '.id' \
	)"

if [[ -z "${FOLDER_ID}" ]]; then
	>&2 echo ":: unable to obtain folderid from bitwarden"
	exit 1
fi

# 1. obtain array of ssh keys from bitwarden
# 2. one base64 value per item for easier looping
QUERY=$(cat <<- "DOC"
		map(
			select(.fields)
			| (.fields | from_entries | {type: .type})
				+ {id: .id, name: .name}
				+ {attachments: (.attachments // []) | map({id: .id, file: .fileName})}
			| select(.type == "ssh")
			| select(.attachments | length > 0)
		)
		| .[]
		| @base64
DOC
)
DATA="$( \
	bw list items \
	--folderid "${FOLDER_ID}" \
	| jq -rM --from-file <(echo ${QUERY}) \
)"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

for ITEM in ${DATA}; do
	_item() {
		base64 --decode <<< "${ITEM}" | jq -rM "${1}"
	}
	NAME="$(_item '.name')"
	ITEM_ID="$(_item '.id')"
	# one base64 value per attachment for easier looping
	ATTACHMENTS="$(_item '.attachments' | jq -rM '.[] | @base64')"

	for ATTACHMENT in ${ATTACHMENTS}; do
		_attachment() {
			base64 --decode <<< "${ATTACHMENT}" | jq -rM "${1}"
		}
		FILE="$(_attachment '.file')"
		ATTACHMENT_ID="$(_attachment '.id')"

		NEW_FILE="${HOME}/.ssh/${FILE}"
		rm -f "${NEW_FILE}"
		bw get attachment "${ATTACHMENT_ID}" \
			--raw \
			--itemid "${ITEM_ID}" \
			> "${NEW_FILE}"
		chmod 400 "${NEW_FILE}"
		echo ":: created ${NEW_FILE} (${NAME})"
	done
done
