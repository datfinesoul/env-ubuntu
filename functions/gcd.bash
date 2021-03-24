gcd () {
	local TARGET
	TARGET="${1}"

	cd "$(git rev-parse --show-toplevel)/${TARGET}"
}
