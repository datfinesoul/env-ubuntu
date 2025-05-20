#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$kernel_name" == "Linux" ]]; then
	# Uninstall conflicting packages
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
		sudo apt-get --yes remove $pkg
	done

	# Add Docker's official GPG key:
	sudo apt-get --yes update
	sudo apt-get --yes install ca-certificates curl
	sudo install -m 0755 -d /etc/apt/keyrings
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	sudo chmod a+r /etc/apt/keyrings/docker.asc

	# Add the repository to Apt sources:
	echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
		$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get --yes update

	# Install the latest version
	sudo apt-get --yes install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

	sudo docker run --rm hello-world
fi
