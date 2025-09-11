#!/usr/bin/env bash

myipv4 () {
	#dig -4 +short myip.opendns.com @resolver1.opendns.com
	dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com
}

myipv6 () {
	#dig -6 +short myip.opendns.com @resolver1.opendns.com
	dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com
}

# Call myipv4 as the primary function
myipv4 "$@"
