#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace
IFS=$'\n\t'

# installing homebrew seems to deal with the xcode requirements

# # type git
# #   that installs development tools
# # then clone
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# remap caps lock to esc
# the below option might be the linux version
#setxkbmap -option caps:escape
# hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'

#sudo systemsetup -listtimezones
#sudo systemsetup -settimezone Asia/Tokyo

export PATH="/opt/homebrew/bin:${PATH}"
brew install coreutils gnu-sed jq bash

# update /etc/shells with /opt/homebrew/bin/bash

chsh -s /opt/homebrew/bin/bash
sudo chsh -s /opt/homebrew/bin/bash
touch ~/.bash_sessions_disable

mkdir "${HOME}/Library/KeyBindings/"
echo '{
    "\UF729"   = "moveToBeginningOfLine:";
    "\UF72B"   = "moveToEndOfLine:";
		"$\UF729" = moveToBeginningOfLineAndModifySelection:; // shift-home
		"$\UF72B" = moveToEndOfLineAndModifySelection:; // shift-end
		"^\UF729" = moveToBeginningOfDocument:; // ctrl-home
		"^\UF72B" = moveToEndOfDocument:; // ctrl-end
		"^$\UF729" = moveToBeginningOfDocumentAndModifySelection:; // ctrl-shift-home
		"^$\UF72B" = moveToEndOfDocumentAndModifySelection:; // ctrl-shift-end
}' > "${HOME}/Library/KeyBindings/DefaultKeyBindings.dict"

sudo softwareupdate --install-rosetta --agree-to-license
