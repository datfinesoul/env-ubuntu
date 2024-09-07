#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

### MODIFY: START
repo="nvm-sh/nvm"
### MODIFY: END

releases="$(gh api "/repos/${repo}/releases/latest")"

# NOTE: sometimes you need ${kernel_name,,}
read -r version url <<< "$(
  printf "%s\n" "${releases}" \
  | jq \
  --arg k "${kernel_name}" \
  --arg a "${architecture}" \
  --arg m "${machine}" \
  -r '[.tag_name, (.assets[].browser_download_url | select(test($k+"_"+$m)))] | @tsv'
)"

info "V:${version}"
info "U:${url}"

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash
