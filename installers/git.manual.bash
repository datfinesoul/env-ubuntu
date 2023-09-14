#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${kernel_name}" == "Darwin" ]]; then
  brew install git
else
  sudo add-apt-repository --yes ppa:git-core/ppa
  sudo apt-get --yes update
  sudo apt-get --yes install git

  VERSION="$(git version | awk '{print $3}')"
  GIT_HTML="/usr/share/doc/git/html"
  wget "https://mirrors.edge.kernel.org/pub/software/scm/git/git-htmldocs-${VERSION}.tar.gz"
  sudo mkdir -p "${GIT_HTML}"
  sudo tar xzf "git-htmldocs-${VERSION}.tar.gz" --directory "${GIT_HTML}"
fi
