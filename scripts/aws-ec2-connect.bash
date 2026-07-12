#!/usr/bin/env bash

if ! command -v jq >/dev/null 2>&1; then
	echo "[!] jq is required for connection history" >&2
	exit 1
fi

history_file="$HOME/.config/aws-ec2-connect/history.json"
region_history_file="$HOME/.config/aws-ec2-connect/region-history.json"

# Abort the whole script on Ctrl+C during selection / AWS calls. Cleared
# before the final interactive SSM session so Ctrl+C keeps working inside it.
trap 'exit 130' INT

# Persist the current connection to history (most-recent first, deduped, max 5)
save_history() {
	local existing='[]'
	if [[ -f "$history_file" ]]; then
		existing="$(cat "$history_file")"
	fi
	mkdir -p "$(dirname "$history_file")"
	local tmp
	tmp="$(mktemp)"
	jq -n \
		--argjson existing "$existing" \
		--arg org "$org" \
		--arg account_name "$account_name" \
		--arg account_id "$account_id" \
		--arg role "$role" \
		--arg region "$default_region" \
		--arg instance_id "$instance_id" \
		--arg instance_name "$instance_name" \
		--arg image_name "$image_name" \
		'([{
			org: $org,
			account_name: $account_name,
			account_id: $account_id,
			role: $role,
			region: $region,
			instance_id: $instance_id,
			instance_name: $instance_name,
			image_name: $image_name
		}] + ($existing | map(select(
			.instance_id != $instance_id
			or .region != $region
			or .account_id != $account_id
			or .role != $role
		)))) | .[0:5]' \
		> "$tmp" && mv "$tmp" "$history_file"
}

# Persist region usage counts per account so the most-used region becomes the
# default for that account on subsequent runs.
save_region_history() {
	local existing='{}'
	if [[ -f "$region_history_file" ]]; then
		existing="$(cat "$region_history_file")"
	fi
	mkdir -p "$(dirname "$region_history_file")"
	local tmp
	tmp="$(mktemp)"
	jq -n \
		--argjson existing "$existing" \
		--arg account_id "$account_id" \
		--arg region "$default_region" \
		'($existing | .[$account_id][$region] = ((.[$account_id][$region] // 0) + 1))' \
		> "$tmp" && mv "$tmp" "$region_history_file"
}

# Return the most-used region for an account (empty if none recorded).
top_region_for_account() {
	local acct="$1"
	local top
	if [[ -f "$region_history_file" ]]; then
		top="$(jq -r --arg acct "$acct" \
			'.[$acct] // {} | to_entries | sort_by(-.value) | .[0].key // empty' \
			"$region_history_file" 2>/dev/null)"
	fi
	echo "$top"
}

mapfile -t profiles < <(awk '
/^\[profile / {
    if (profile != "") print profile, role, acct
    line = $0
    gsub(/^\[profile /, "", line)
    gsub(/\]$/, "", line)
    n = split(line, parts, "/")
    if (n == 3) {
        profile = parts[1] " " parts[2]
        role = parts[3]
    } else {
        profile = ""
        role = ""
    }
    acct = ""
    next
}
/sso_account_id/ {
    split($0, a, "=")
    gsub(/^[ \t]+|[ \t]+$/, "", a[2])
    acct = a[2]
}
END {
    if (profile != "") print profile, role, acct
}
' ~/.aws/config)

# Build the history rows for the top-level menu (fields: type, index, display)
history_lines=()
if [[ -f "$history_file" ]]; then
	mapfile -t history_lines < <(jq -r '
		to_entries[]
		| "prev\t\(.key)\t[prev] \(.value.instance_name)  \(.value.account_name)  \(.value.region)  (\(.value.instance_id))"
	' "$history_file" 2>/dev/null)
fi

# Build the org rows for the top-level menu (fields: type, org, display)
mapfile -t org_lines < <( \
	printf '%s\n' "${profiles[@]}" \
	| awk '{print $1}' \
	| sort -u \
	| awk '{print "org\t"$0"\t"$0}' \
)

selection="$( \
	{
		[[ ${#history_lines[@]} -gt 0 ]] && printf '%s\n' "${history_lines[@]}"
		printf '%s\n' "${org_lines[@]}"
	} \
	| fzf --prompt="Select Org or [prev]: " \
	--delimiter=$'\t' \
	--with-nth=3 \
	--height=15 \
	--layout=reverse \
	--no-multi \
	--header="Pick a previous connection ([prev]) or an Org" \
	--bind="esc:clear-query" \
)"
if [[ -z "$selection" ]]; then
	exit 1
fi

sel_type="$(cut -f1 <<< "$selection")"
sel_key="$(cut -f2 <<< "$selection")"

if [[ "$sel_type" == "prev" ]]; then
	# Reconnect using a stored connection; skip all other selection steps.
	entry="$(jq -r ".[$sel_key]" "$history_file")"
	org="$(jq -r '.org' <<< "$entry")"
	account_name="$(jq -r '.account_name' <<< "$entry")"
	account_id="$(jq -r '.account_id' <<< "$entry")"
	role="$(jq -r '.role // "SRE"' <<< "$entry")"
	default_region="$(jq -r '.region' <<< "$entry")"
	instance_id="$(jq -r '.instance_id' <<< "$entry")"
	instance_name="$(jq -r '.instance_name' <<< "$entry")"
	image_name="$(jq -r '.image_name' <<< "$entry")"

	export org account_name account_id role default_region

	echo "[i] logging into $account_name ($account_id) as $role"
	. assume "${org}/${account_name}/${role}"

	echo "[i] AMI: $image_name"
	echo "[i] connecting to $instance_id ($instance_name)"

	# Bump this connection to the top of the history.
	save_history
	save_region_history
else
	org="$sel_key"

	account_name="$( \
		printf '%s\n' "${profiles[@]}" \
		| grep "^$org " \
		| awk '{print $2}' \
		| sort -u \
		| fzf --prompt="Select Account: " \
		--height=10 \
		--layout=reverse \
		--no-multi \
		--bind="esc:clear-query" \
	)"
	if [[ -z "$account_name" ]]; then
		exit 1
	fi

	account_id="$( \
		printf '%s\n' "${profiles[@]}" \
		| awk -v org="$org" -v name="$account_name" '$1 == org && $2 == name {print $4}' \
		| head -n1 \
	)"

	mapfile -t roles_for_account < <( \
		printf '%s\n' "${profiles[@]}" \
		| awk -v org="$org" -v name="$account_name" '$1 == org && $2 == name {print $3}' \
		| sort -u \
	)
	if [[ "${#roles_for_account[@]}" -eq 0 || -z "${roles_for_account[0]}" ]]; then
		echo "[!] No roles found for $org/$account_name" >&2
		exit 1
	elif [[ "${#roles_for_account[@]}" -eq 1 ]]; then
		role="${roles_for_account[0]}"
	else
		role="$( \
			printf '%s\n' "${roles_for_account[@]}" \
			| fzf --prompt="Select Role: " \
			--height=10 \
			--layout=reverse \
			--no-multi \
			--bind="esc:clear-query" \
		)"
		if [[ -z "$role" ]]; then
			exit 1
		fi
	fi

	base_region="us-east-1"
	additional_regions=("ap-southeast-1" "eu-west-1" "us-west-2")

	# Default to the most-used region for this account. When no region has
	# been used yet for this account, present the candidate list in its
	# natural order with no preselected default. Otherwise the most-used
	# region is moved to the top of the candidate list so it is visually
	# preselected.
	top_region="$(top_region_for_account "$account_id")"

	if [[ -n "$top_region" ]]; then
		regions=("$top_region")
		for r in "$base_region" "${additional_regions[@]}"; do
			[[ "$r" != "$top_region" ]] && regions+=("$r")
		done
	else
		regions=("$base_region" "${additional_regions[@]}")
	fi

	default_region="$( \
		printf '%s\n' "${regions[@]}" \
		| fzf --prompt="Select Region: " \
		--query="$top_region" \
		--height=10 \
		--layout=reverse \
		--no-multi \
		--bind="esc:clear-query" \
	)"
	if [[ -z "$default_region" ]]; then
		exit 1
	fi

	export org account_name account_id role default_region

	echo "[i] logging into $account_name ($account_id) as $role"
	. assume "${org}/${account_name}/${role}"

	echo "[i] Looking for the instance..."
	# AWS `--output text` is tab-delimited; keep tabs as the field separator so
	# instance names containing spaces don't corrupt the columns.
	instances_raw="$( \
		aws ec2 describe-instances \
		--filters "Name=instance-state-name,Values=running" \
		--query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`].Value | [0], PrivateIpAddress, ImageId, InstanceType, LaunchTime]' \
		--output text \
		--region "$default_region" \
		| sort -t$'\t' -k6,6 -r \
	)"
	if [[ -z "$instances_raw" ]]; then
		echo "[!] No running instances found in $default_region" >&2
		exit 1
	fi

	# Each menu line is: <aligned display>\t<instance_id>\t<instance_name>\t<image_id>
	# fzf displays only the first (aligned) field; the trailing tab-delimited
	# fields carry the real values so we never re-parse the display text.
	selected_instance="$( \
		paste -d$'\t' \
			<(printf '%s\n' "$instances_raw" | column -t -s $'\t') \
			<(printf '%s\n' "$instances_raw" | awk -F'\t' 'BEGIN{OFS="\t"}{print $1, $2, $4}') \
		| fzf --prompt="Select Instance: " \
		--delimiter=$'\t' \
		--with-nth=1 \
		--height=10 \
		--layout=reverse \
		--no-multi \
		--header="Instance-ID Name Private-IP Image-ID Instance-Type Launch-Time" \
		--bind="esc:clear-query" \
	)"
	if [[ -z "$selected_instance" ]]; then
		exit 1
	fi

	instance_id="$(cut -f2 <<< "$selected_instance")"
	instance_name="$(cut -f3 <<< "$selected_instance")"
	image_id="$(cut -f4 <<< "$selected_instance")"

	image_name="$( \
		aws ec2 describe-images \
		--image-ids "$image_id" \
		--region "$default_region" \
		--query 'Images[0].Name' \
		--output text \
	)"

	echo "[i] AMI: $image_name ($image_id)"
	echo "[i] connecting to $instance_id"

	# Record this connection before starting the session.
	save_history
	save_region_history
fi

# Hand control of Ctrl+C to the interactive SSM session from here on.
trap - INT

ssm_args=()
case "$image_name" in
	al2-*|al2023-*|glg-*)
		ssm_args=(--document-name "AWS-StartInteractiveCommand" --parameters 'command=sudo su - ec2-user')
		;;
esac

aws ssm start-session --target "$instance_id" --region "$default_region" "${ssm_args[@]}"
