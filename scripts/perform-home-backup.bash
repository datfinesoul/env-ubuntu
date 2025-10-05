#!/usr/bin/env bash

alias perform-home-backup=perform_home_backup
perform_home_backup() {
	local backup_destination="$1"
	local home_directory="${2:-$HOME}"

	# Validate input
	if [ -z "$backup_destination" ]; then
		echo "Usage: perform_home_backup <remote_user@remote_host:/path/to/backup> [optional_home_directory]" >&2
		return 1
	fi

	# Perform rsync backup with SSH and extensive exclusions
	rsync -avz --delete --delete-excluded \
		--exclude='*.deb' \
		--exclude='*.dmg' \
		--exclude='*.log' \
		--exclude='*.pkg' \
		--exclude='*.tmp' \
		--exclude='.aws-sam/aws-sam-cli-app-templates/' \
		--exclude='.cache/' \
		--exclude='.config/Code/logs/' \
		--exclude='.config/google-chrome/' \
		--exclude='.DS_Store' \
		--exclude='.fseventsd/' \
		--exclude='.git/' \
		--exclude='.local/share/pnpm/' \
		--exclude='.local/share/Trash/' \
		--exclude='.next/cache/' \
		--exclude='.npm/' \
		--exclude='.Spotlight-V100/' \
		--exclude='.ssh/' \
		--exclude='.terraform.d/plugin-cache/' \
		--exclude='.Trashes/' \
		--exclude='.vscode/' \
		--exclude='.zoom/data/' \
		--exclude='Downloads/temp/' \
		--exclude='go/pkg/' \
		--exclude='Library/Application Support/CrashReporter/' \
		--exclude='Library/Caches/' \
		--exclude='Library/Developer/Xcode/DerivedData/' \
		--exclude='Library/Logs/' \
		--exclude='Library/Preferences/ByHost/' \
		--exclude='Library/Saved Application State/' \
		--exclude='Library/WebKit/WebKitCache/' \
		--exclude='node_modules/' \
		--exclude='snap/' \
		--exclude='.config/Jan/' \
		--exclude='.config/Slack/' \
		--exclude='.lmstudio/' \
		"$home_directory/" \
		"$backup_destination"
}

# Call the function with all arguments
perform_home_backup "$@"
