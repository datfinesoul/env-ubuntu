#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

sudo apt-get --yes remove vim || true
sudo apt-get --yes remove vi || true

#sudo apt-get --yes update
#sudo apt-get --yes install \
#  libncurses5-dev \
#  libgtk2.0-dev \
#  libatk1.0-dev \
#  libcairo2-dev \
#  libx11-dev \
#  libxpm-dev \
#  libxt-dev \
#  python-dev \
#  python3-dev \
#  ruby-dev \
#  lua5.1 \
#  lua5.1-dev \
#  libperl-dev
git clone "https://github.com/vim/vim.git"
cd vim || exit
git checkout "$(git tag | tail -n1)"
./configure --with-features=huge
make
sudo make install
make clean
make distclean

echo ":: if vim is not found, type 'hash -d vim'"
