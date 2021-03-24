ipv6 () {
	local setting
	[[ "$1" == "off" ]] && setting="1" || setting="0"

	echo "setting: ${setting}"
	sudo sysctl -w net.ipv6.conf.all.disable_ipv6="${setting}"
	sudo sysctl -w net.ipv6.conf.default.disable_ipv6="${setting}"
	sudo sysctl -w net.ipv6.conf.lo.disable_ipv6="${setting}"

	ip a
}
