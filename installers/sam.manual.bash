#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${kernel_name}" == "Darwin" ]]; then
  false
else
  wget \
    --quiet \
    "$(printf '%s' \
    "https://github.com/aws/aws-sam-cli/releases/latest/download" \
    "/aws-sam-cli-linux-${machine}.zip"
    )"
  unzip "aws-sam-cli-linux-${machine}.zip"
  if [[ "$(which sam > /dev/null && echo "found" || echo "missing")" == "missing" ]]; then
    sudo './install'
  else
    sudo './install' --update
  fi
fi
