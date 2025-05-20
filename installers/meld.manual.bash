#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${kernel_name}" == "Darwin" ]]; then
	true
else
  sudo apt-get --yes update
  sudo apt-get --yes install \
    cmake \
    libgtk-3-dev \
    libgtksourceview-4-dev \
    python-gi-dev \
    python3-gi-cairo \
		python3-cairo-dev \
		python3 \
		python3-pip \
		python3-setuptools \
		python3-wheel \
		ninja-build \
		itstool

	pip3 install --user meson

  git clone 'https://gitlab.gnome.org/GNOME/meld.git'
  cd meld
  meson -Dprefix="${HOME}/.local" _build
  cd _build
  ninja
  ninja install
fi

# vim: set ft=bash :
