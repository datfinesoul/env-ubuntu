#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# Check if running on supported system
if ! command -v apt &> /dev/null; then
	echo "Error: This script requires apt package manager (Ubuntu/Debian)" >&2
	exit 1
fi

# Function to check if Typora repository is already configured
is_typora_repo_configured() {
	if [[ -f /etc/apt/sources.list.d/typora.list ]] || \
	   grep -q "typora.io/linux" /etc/apt/sources.list 2>/dev/null || \
	   find /etc/apt/sources.list.d/ -name "*.list" -exec grep -l "typora.io/linux" {} \; 2>/dev/null | grep -q .; then
		return 0
	fi
	return 1
}

# Function to check if GPG key is installed
is_typora_key_installed() {
	if [[ -f /etc/apt/trusted.gpg.d/typora.asc ]] || \
	   apt-key list 2>/dev/null | grep -q "typora" 2>/dev/null; then
		return 0
	fi
	return 1
}

repo_updated=false

# Install GPG key if not present
if ! is_typora_key_installed; then
	echo "Installing Typora GPG key..."
	wget -qO - https://typora.io/linux/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/typora.asc > /dev/null
	repo_updated=true
fi

# Add repository if not configured
if ! is_typora_repo_configured; then
	echo "Adding Typora repository..."
	sudo add-apt-repository 'deb https://typora.io/linux ./' -y
	repo_updated=true
fi

# Update package list only if repository was modified
if [[ "$repo_updated" == true ]]; then
	echo "Updating package list..."
	sudo apt update
fi

# Install or update Typora
if ! dpkg -l | grep -q "^ii.*typora" || apt list --upgradable 2>/dev/null | grep -q typora; then
	if dpkg -l | grep -q "^ii.*typora"; then
		echo "Updating Typora..."
	else
		echo "Installing Typora..."
	fi
	sudo apt-get install typora -y
fi
echo
