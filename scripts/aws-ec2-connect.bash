#!/usr/bin/env bash
mapfile -t profiles < <(awk '
/^\[profile / {
    if (profile != "") print profile, acct
    line = $0
    gsub(/^\[profile /, "", line)
    gsub(/\]$/, "", line)
    n = split(line, parts, "/")
    if (n == 3) {
        profile = parts[1] " " parts[2]
    } else {
        profile = ""
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
    if (profile != "") print profile, acct
}
' ~/.aws/config)

org="$( \
	printf '%s\n' "${profiles[@]}" \
	| awk '{print $1}' \
	| sort -u \
	| fzf --prompt="Select Org: " \
	--height=10 \
	--layout=reverse \
	--no-multi \
	--bind="esc:clear-query" \
)"
if [[ -z "$org" ]]; then
	exit 1
fi

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
	| awk -v org="$org" -v name="$account_name" '$1 == org && $2 == name {print $3}' \
	| head -n1 \
)"

base_region="us-east-1"
additional_regions=("ap-southeast-1" "eu-west-1" "us-west-2")

default_region="$( \
	printf '%s\n' "$base_region" "${additional_regions[@]}" \
	| fzf --prompt="Select Region: " \
	--query="$base_region" \
	--height=10 \
	--layout=reverse \
	--no-multi \
	--bind="esc:clear-query" \
)"
if [[ -z "$default_region" ]]; then
	exit 1
fi

export org account_name account_id default_region

echo "[i] logging into $account_name ($account_id)"
. assume "${org}/${account_name}/SRE"

echo "[i] Looking for the instance..."
selected_instance="$( \
	aws ec2 describe-instances \
	--filters "Name=instance-state-name,Values=running" \
	--query 'Reservations[].Instances[].[InstanceId, Tags[?Key==`Name`].Value | [0], PrivateIpAddress, ImageId, LaunchTime]' \
	--output text \
	--region "$default_region" \
	| sort -k5 -r \
	| column -t \
	| fzf --prompt="Select Instance: " \
	--height=10 \
	--layout=reverse \
	--no-multi \
	--header="Instance-ID Name Private-IP Image-ID Launch-Time" \
	--bind="esc:clear-query" \
)"
if [[ -z "$selected_instance" ]]; then
	exit 1
fi

instance_id="$(awk '{print $1}' <<< "$selected_instance")"
image_id="$(awk '{print $4}' <<< "$selected_instance")"

image_name="$( \
	aws ec2 describe-images \
	--image-ids "$image_id" \
	--region "$default_region" \
	--query 'Images[0].Name' \
	--output text \
)"

echo "[i] AMI: $image_name ($image_id)"
echo "[i] connecting to $instance_id"

ssm_args=()
case "$image_name" in
	al2-*|al2023-*|glg-*)
		ssm_args=(--document-name "AWS-StartInteractiveCommand" --parameters 'command=sudo su - ec2-user')
		;;
esac

aws ssm start-session --target "$instance_id" --region "$default_region" "${ssm_args[@]}"
