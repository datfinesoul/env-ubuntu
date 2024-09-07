#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# https://github.com/wagoodman/dive
export VERSION="0.10.0"
wget "https://github.com/wagoodman/dive/releases/download/v${VERSION}/dive_${VERSION}_linux_amd64.deb"
sudo apt-get -y install "./dive_${VERSION}_linux_amd64.deb"
