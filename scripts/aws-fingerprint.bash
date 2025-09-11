#!/usr/bin/env bash

#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/verify-keys.html
alias aws-fingerprint=aws_fingerprint
aws_fingerprint () {
	openssl pkcs8 -in "$1" -inform PEM -outform DER -topk8 -nocrypt \
		| openssl sha1 -c
}

# Call the function with all arguments
aws_fingerprint "$@"
