aws-assume() {
  # if a profile was set, remove all the other creds
  if [[ -n "${AWS_PROFILE}" ]]; then
    unset \
      AWS_ACCESS_KEY_ID \
      AWS_SECRET_ACCESS_KEY \
      AWS_SESSION_TOKEN \
      AWS_CREDENTIALS_EXPIRATION
  fi

  local role payload
  role="${1}"
  duration="${2:-3600}"
  payload="$(aws sts assume-role \
    --role-arn "${role}" \
    --role-session-name 'AWSCLI-Developer-Session' \
    --duration-seconds "${duration}" \
    | jq -rM '.Credentials |
      {
        "AWS_ACCESS_KEY_ID": .AccessKeyId,
        "AWS_SECRET_ACCESS_KEY": .SecretAccessKey,
        "AWS_SESSION_TOKEN": .SessionToken,
        "AWS_CREDENTIALS_EXPIRATION": .Expiration
      } | keys[] as $k | "export \($k)=\(.[$k])"'
  )"
  if [[ -n "${payload}" ]]; then
    # the . /dev/stdin <<< "$(cat <())" hack is for OSX bash 3.2
    # https://stackoverflow.com/questions/32596123/why-source-command-doesnt-work-with-process-substitution-in-bash-3-2
    . /dev/stdin <<<"$(echo "${payload}")"
  fi
}
