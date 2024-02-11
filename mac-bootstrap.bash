#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

# remap caps lock to esc
#setxkbmap -option caps:escape
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'

chsh -s /bin/bash
touch ~/.bash_sessions_disable
brew install coreutils gnu-sed

# this is supposed to fail to confirm a version of readlink is not in the path
type -t readlink || true

# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

type -t readlink
# #!/usr/bin/env bash
# 
# # type git
# #   that installs development tools
# # then clone
# 
# 
# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# brew install coreutils
