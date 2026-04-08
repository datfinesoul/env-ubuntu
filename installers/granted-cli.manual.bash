#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${kernel_name}" == "Darwin" ]]; then
  brew tap common-fate/granted
  brew install common-fate/granted/granted
  exit 0
fi

### MODIFY: START
repo="fwdcloudsec/granted"
### MODIFY: END

releases="$(gh api "/repos/${repo}/releases/latest")"

# NOTE: sometimes you need ${kernel_name,,}
read -r version url <<< "$(
  printf "%s\n" "${releases}" \
  | jq \
  --arg k "${kernel_name,,}" \
  --arg a "${architecture}" \
  --arg m "${machine}" \
  --arg r "${release_arch}" \
  -r '[.tag_name, (.assets[].browser_download_url | select(test($k+"_"+$r+".tar.gz$")))] | @tsv'
)"

info "V:${version}"
info "U:${url}"

if [[ -z "${url}" ]]; then
  fail "unable to find match, displaying all files for debugging"
  printf "%s\n" "${releases}" \
    | jq -r '[.tag_name, (.assets[].browser_download_url)]'
  exit 1
fi

zip_file="${url##*/}"
version="${version#*v}"

info "ZF:${zip_file}"

gh release download "v${version}" -R "${repo}" -p "${zip_file}"

target_dir="${HOME}/.local/granted/${version}"
bin_dir="${HOME}/.local/bin"

mkdir -p "${target_dir}"
mkdir -p "${bin_dir}"

tar xzf "${zip_file}"

mv granted "${target_dir}/granted"
mv assume "${target_dir}/assume"
[[ -f "assumego" ]] && mv assumego "${target_dir}/assumego"

ln -sf "${target_dir}/granted" "${bin_dir}/granted"
ln -sf "${target_dir}/assume" "${bin_dir}/assume"
[[ -f "${target_dir}/assumego" ]] && ln -sf "${target_dir}/assumego" "${bin_dir}/assumego"

info "granted ${version} installed"
plain "\ngranted sso populate --prune --sso-region ap-northeast-1 --prefix 'io/' --no-credential-process https://u-io.awsapps.com/start\n"
