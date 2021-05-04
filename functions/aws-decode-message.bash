aws-decode-message () {
local CODE
CODE="${1}"
aws sts decode-authorization-message \
	--encoded-message "${CODE}" \
	--query DecodedMessage --output text \
	| jq '.'
}
