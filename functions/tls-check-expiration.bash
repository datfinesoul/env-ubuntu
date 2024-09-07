alias tls-check-expiration=tls_check_expiration
tls_check_expiration () {
local domain
domain="$1"
echo | openssl s_client -connect "${domain}:443" 2>/dev/null | openssl x509 -noout -dates
}
