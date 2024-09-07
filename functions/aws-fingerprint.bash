alias aws-fingerprint=aws_fingerprint
aws_fingerprint () {
	openssl pkcs8 -in "$1" -inform PEM -outform DER -topk8 -nocrypt \
		| openssl sha1 -c
}
