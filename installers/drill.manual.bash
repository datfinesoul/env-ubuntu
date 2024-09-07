#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

curl -L "https://dlcdn.apache.org/drill/1.21.2/apache-drill-1.21.2.tar.gz" | tar xzf -
#cd apache-drill-1.21.2
#find ./bin/ -executable -type f ! -name '*.*' | xargs -I{} cp {} "$HOME/.local/bin"

# TODO: The installer is not complete.  Need to copy the whole dir to .local, and then symlink
# some files, but wasn't 100% sure.
