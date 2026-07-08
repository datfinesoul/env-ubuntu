exec 9>/tmp/history-compression.lock
flock -n 9 || true
"$ENV_UBUNTU_ROOT/scripts/history-compression.bash" --no-dry-run || true
