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
        --exclude='.ssh/' \
        --exclude='.git/' \
        --exclude='node_modules/' \
        --exclude='.cache/' \
        --exclude='.npm/' \
        --exclude='.vscode/' \
        --exclude='.local/share/Trash/' \
        --exclude='Downloads/temp/' \
        --exclude='*.log' \
        --exclude='*.tmp' \
        --exclude='.Spotlight-V100/' \
        --exclude='.Trashes/' \
        --exclude='.fseventsd/' \
        --exclude='Library/Caches/' \
        --exclude='Library/Application Support/CrashReporter/' \
        --exclude='Library/Logs/' \
        --exclude='Library/Preferences/ByHost/' \
        --exclude='Library/Developer/Xcode/DerivedData/' \
        --exclude='Library/Saved Application State/' \
        --exclude='Library/WebKit/WebKitCache/' \
        --exclude='.DS_Store' \
        --exclude='*.dmg' \
        --exclude='*.pkg' \
        --exclude='snap/' \
				--exclude='go/pkg/mod/cache/' \
				--exclude='.zoom/data/cefcache/' \
				--exclude='.terraform.d/plugin-cache/' \
				--exclude='.next/cache/' \
        "$home_directory/" \
        "$backup_destination"
}
