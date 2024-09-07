#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

version="${1:-1.22.0}"

if [[ "${kernel_name}" == 'Darwin' ]]; then
  false
else
  wget \
    --quiet \
    "$(printf '%s' \
    "https://golang.org/dl/go${version}.linux-${architecture}.tar.gz" \
    )"
  sudo rm -rf '/usr/local/go'
  sudo tar -C '/usr/local' -xzf "go${version}.linux-${architecture}.tar.gz"
fi
go install golang.org/x/tools/gopls@latest
# go vet -vettool=$(which shadow)
go install 'golang.org/x/tools/go/analysis/passes/shadow/cmd/shadow@latest'
