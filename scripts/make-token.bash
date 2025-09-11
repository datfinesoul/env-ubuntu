#!/usr/bin/env bash

alias make-token=make_token
make_token () {
	local length
	length="${1:-20}"
	if [[ ! "$length" =~ ^[0-9]+$ ]]; then
		length='20'
	fi
	python3 -c "import secrets; print(secrets.token_hex($length), end='')"
}

# Call the function with all arguments
make_token "$@"
