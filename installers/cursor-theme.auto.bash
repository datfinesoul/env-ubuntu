#!/usr/bin/env bash
# Install the Bibata-Modern-Ice cursor theme and select it in GNOME.
# The Pop default is solid black, which is invisible over light terminal themes.
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${kernel_name}" == "Darwin" ]]; then
  >&2 echo 'No Darwin Install'
  exit 0
fi

if ! command -v gsettings > /dev/null 2>&1; then
  >&2 echo 'No GNOME/gsettings found'
  exit 0
fi

theme_name="Bibata-Modern-Ice"
theme_version="2.0.6"
icons_dir="${HOME}/.icons"
theme_dir="${icons_dir}/${theme_name}"
tarball_url="https://github.com/ful1e5/Bibata_Cursor/releases/download/v${theme_version}/${theme_name}.tar.xz"

if [[ ! -f "${theme_dir}/index.theme" ]]; then
  info ":: downloading ${theme_name} v${theme_version}"
  mkdir -p "${icons_dir}"
  curl -fsSL --retry 3 -o "${theme_name}.tar.xz" "${tarball_url}"
  tar -xf "${theme_name}.tar.xz" -C "${icons_dir}"
  rm -f "${theme_name}.tar.xz"
fi

current_theme="$(gsettings get org.gnome.desktop.interface cursor-theme 2> /dev/null || true)"
if [[ "${current_theme}" != "'${theme_name}'" ]]; then
  info ":: selecting ${theme_name} cursor theme"
  gsettings set org.gnome.desktop.interface cursor-theme "${theme_name}"
fi

# vim: set ft=bash :
