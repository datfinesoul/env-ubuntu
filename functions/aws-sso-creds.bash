aws-sso-creds() {
  unset \
    AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY \
    AWS_SESSION_TOKEN \
    AWS_CREDENTIALS_EXPIRATION \
    AWS_REGION

  local profile
  profile="${1:-${AWS_PROFILE}}"
  if [[ -z "${profile}" ]]; then
    >&2 echo ":: missing profile"
    return 1
  fi

  local account_id role_name region start_url
  account_id="$(aws configure get sso_account_id --profile ${profile})"
  role_name="$(aws configure get sso_role_name --profile ${profile})"
  region="$(aws configure get region --profile ${profile})"
  region="${region:-us-east-1}"
  start_url="$(aws configure get sso_start_url --profile "${profile}")"

  if [ -z "$start_url" ] ; then
    >&2 echo ":: missing sso_start_url for profile ${profile}"
    return 1
  fi

  local cache_sha cache_file
  cache_sha="$(echo -n "$start_url" | sha1sum | awk '{print $1}')"
  cache_file="${HOME}/.aws/sso/cache/${cache_sha}.json"

  local access_token payload
  access_token="$(<"${cache_file}" jq -rM '.accessToken')"
  payload="$(aws sso get-role-credentials \
    --account-id "${account_id}" \
    --role-name "${role_name}" \
    --region "${region}" \
    --access-token "${access_token}" \
    --no-sign-request \
    --output json \
    | jq -rM '.roleCredentials |
      {
        "AWS_ACCESS_KEY_ID": .accessKeyId,
        "AWS_SECRET_ACCESS_KEY": .secretAccessKey,
        "AWS_SESSION_TOKEN": .sessionToken,
        "AWS_CREDENTIALS_EXPIRATION": (.expiration / 1000 | todate)
      } | keys[] as $k | "export \($k)=\(.[$k])"'
  )"
  if [[ -n "${payload}" ]]; then
    # the . /dev/stdin <<< "$(cat <())" hack is for OSX bash 3.2
    # https://stackoverflow.com/questions/32596123/why-source-command-doesnt-work-with-process-substitution-in-bash-3-2
    . /dev/stdin <<<"$(echo "${payload}")"
    export AWS_REGION="${region}"
    unset AWS_PROFILE
  fi
}
