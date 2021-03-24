# vi: noet :
# noet because we need tabs for the heredoc
aws-fingerprint () {
	openssl pkcs8 -in "$1" -inform PEM -outform DER -topk8 -nocrypt \
		| openssl sha1 -c
}
