#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

### MODIFY: START
repo="nektos/act"
### MODIFY: END

executable="${repo##*/}"
bin_dir="${HOME}/.local/bin"
# cleanup pre-gh cli installs
rm -f "${bin_dir}/${executable}"

gh extension install "https://github.com/nektos/gh-act"
gh extension upgrade act
