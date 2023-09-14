#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html
if [[ "${kernel_name}" == "Darwin" ]]; then
	>&2 echo 'No Darwin Install'
else
	curl -L 'https://sw.kovidgoyal.net/kitty/installer.sh' | \
		sh /dev/stdin launch=n

	mkdir -p "${HOME}/.local/bin/"
	ln -sf "${HOME}/.local/kitty.app/bin/kitty" "${HOME}/.local/bin/"
	#cp "${HOME}/.local/kitty.app/share/applications/kitty.desktop" "${HOME}/.local/share/applications"
	cat > "${HOME}/.local/share/applications/kitty.desktop" <<-DOC
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=Kitty
	Exec=${HOME}/.local/bin/kitty
	Terminal=false
	Icon=${HOME}/.local/share/icons/hicolor/256x256/apps/kitty.png
	DOC
	rsync -avz "${HOME}/.local/kitty.app/share/icons/"* "${HOME}/.local/share/icons/"

	#sed -i -e 's|Icon=kitty|Icon=/home/'"${USER}"'/.local/share/icons/hicolor/256x256/apps/kitty.png|g' \
	#  "${HOME}/.local/share/applications/kitty.desktop"
fi
