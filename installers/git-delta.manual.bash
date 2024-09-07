#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

### MODIFY: START
repo="dandavison/delta"
### MODIFY: END

releases="$(gh api "/repos/${repo}/releases/latest")"

# NOTE: sometimes you need ${kernel_name,,}
read -r version url <<< "$(
  printf "%s\n" "${releases}" \
  | jq \
  --arg k "${kernel_name}" \
  --arg a "${architecture}" \
  --arg m "${machine}" \
  -r '[.tag_name, (.assets[].browser_download_url | select(test($a+".deb") and (test("musl") | not)))] | @tsv'
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
executable="${repo##*/}"
#executable="${install_name}"
versioned_exe="${executable}_${version}"

info "ZF:${zip_file}"
info "E:${executable}"
info "VE:${versioned_exe}"

gh release download "${version}" -R "${repo}" -p "${zip_file}"

target_dir="${HOME}/.local/${executable}"
bin_dir="${HOME}/.local/bin"

mkdir -p "${target_dir}"
mkdir -p "${bin_dir}"

#tar xzf "${zip_file}"
#tar xf "${zip_file}"
#unzip "${zip_file}"

#mv "${executable}" "${target_dir}/${versioned_exe}"

if [[ "${kernel_name}" == "Darwin" ]]; then
  brew install git-delta
else
  sudo dpkg -i "${zip_file}"
fi
