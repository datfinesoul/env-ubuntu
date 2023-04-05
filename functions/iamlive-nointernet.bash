iamlive-nointernet () {
if [[ "${1:-}" == "--proxy" ]]; then
	shift
	#sudo -g no-internet "$(which iamlive)" --set-ini --profile "${AWS_PROFILE}" --mode proxy --output-file ./iam.json
	"$(which iamlive)" --mode proxy --output-file ./iam.json
else
	getent group "no-internet" || sudo addgroup no-internet
	if ! sudo iptables -C OUTPUT -m owner --gid-owner no-internet -j DROP; then
	sudo iptables -A OUTPUT -m owner --gid-owner no-internet -j DROP
	fi
	if ! sudo ip6tables -C OUTPUT -m owner --gid-owner no-internet -j DROP; then
	sudo ip6tables -A OUTPUT -m owner --gid-owner no-internet -j DROP
	fi
	sudo -g no-internet "$(which iamlive)"
fi
}
