#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

### MODIFY: START
repo="caddyserver/caddy"
### MODIFY: END

releases="$(curl -s "https://api.github.com/repos/${repo}/releases/latest")"

# NOTE: sometimes you need ${kernel_name,,}
if [[ "$kernel_name" == 'Darwin' ]]; then
	read -r version url <<< "$(
		printf "%s\n" "${releases}" \
		| jq \
		--arg k "mac" \
		--arg a "${architecture}" \
		--arg m "${machine}" \
		-r '[.tag_name, (.assets[].browser_download_url | select(test($k+"_"+$a+".tar.gz$")))] | @tsv'
	)"
else
	read -r version url <<< "$(
		printf "%s\n" "${releases}" \
		| jq \
		--arg k "${kernel_name,,}" \
		--arg a "${architecture}" \
		--arg m "${machine}" \
		-r '[.tag_name, (.assets[].browser_download_url | select(test($k+"_"+$a+".tar.gz$")))] | @tsv'
	)"
fi

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
versioned_exe="${executable}_${version}"

info "ZF:${zip_file}"
info "E:${executable}"
info "VE:${versioned_exe}"

#gh release download "${version}" -R "${repo}" -p "${zip_file}"
curl -o caddy "https://caddyserver.com/api/download?os=${kernel_name,,}&arch=${architecture}&p=github.com%2Fcaddyserver%2Fforwardproxy"
chmod 770 caddy

target_dir="${HOME}/.local/${executable}"
bin_dir="${HOME}/.local/bin"

mkdir -p "${target_dir}"
mkdir -p "${bin_dir}"

#tar xzf "${zip_file}"
#tar xf "${zip_file}"
#unzip "${zip_file}"

#mv "${executable}_${kernel_name,,}_${architecture}" "${executable}"
mv "${executable}" "${target_dir}/${versioned_exe}"

if [[ "${kernel_name}" == "Darwin" ]]; then
  ln -sf "${target_dir}/${versioned_exe}" "${bin_dir}/${executable}"
else
  ln --symbolic --force "${target_dir}/${versioned_exe}" "${bin_dir}/${executable}"
fi
