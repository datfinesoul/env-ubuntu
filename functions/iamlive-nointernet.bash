iamlive-nointernet () {
getent group "no-internet" || sudo addgroup no-internet
if ! sudo iptables -C OUTPUT -m owner --gid-owner no-internet -j DROP; then
sudo iptables -A OUTPUT -m owner --gid-owner no-internet -j DROP
fi
if ! sudo ip6tables -C OUTPUT -m owner --gid-owner no-internet -j DROP; then
sudo ip6tables -A OUTPUT -m owner --gid-owner no-internet -j DROP
fi
if [[ "${1:-}" == "--proxy" ]]; then
	shift
	sudo -g no-internet "$(which iamlive)" --mode proxy
else
	sudo -g no-internet "$(which iamlive)"
fi
}
