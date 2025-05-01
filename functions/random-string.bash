alias random-string=random_string
random_string() {
  if [ $# -lt 1 ]; then
    echo "Usage: random_string LENGTH [CHARSET]"
    echo "  LENGTH: Number of characters to generate"
    echo "  CHARSET: Optional character set (default: a-z0-9)"
    return 1
  fi
  local length="$1"
  if ! [[ "$length" =~ ^[0-9]+$ ]]; then
    echo "Error: LENGTH must be a positive number"
    return 1
  fi
	local charset="${2:-a-z0-9}"
  < /dev/urandom tr -dc "$charset" | head -c "$length"
}
