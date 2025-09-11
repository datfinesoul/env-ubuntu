#!/usr/bin/env bash

alias aws-decode-message=aws_decode_message
aws_decode_message () {
local CODE
CODE="${1}"
aws sts decode-authorization-message \
	--encoded-message "${CODE}" \
	--query DecodedMessage --output text \
	| jq '.'
}

# Call the function with all arguments
aws_decode_message "$@"
