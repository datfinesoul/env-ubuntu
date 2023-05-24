aws-clear-env() {
  local VARS
  #mapfile -t VARS < <(env | awk -F'=' '/^AWS_/ {print $1}')
  IFS=$'\n' read -r -d '' -a VARS < <(env | awk -F'=' '/^AWS_/ {print $1}')
  unset "${VARS[@]}"
  unset HTTP_PROXY HTTPS_PROXY
}
