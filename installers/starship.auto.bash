#!/usr/bin/env bash
# shellcheck disable=SC1091
source '_core.bash'

mkdir -p "${HOME}/.local/bin"
curl -sS 'https://starship.rs/install.sh' -o /tmp/install.sh
chmod 700 /tmp/install.sh
/tmp/install.sh -b "${HOME}/.local/bin" --yes

info "cd '${HOME}/env-ubuntu' && ./dotloader.bash bashrc"
