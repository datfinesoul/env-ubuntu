# shellcheck source=./_core.bash
. "$(dirname "${0}")/_core.bash"

REPO="${1}"
TARGET="${1##*/}"
TARGET="${TARGET%.git}"
METHOD="${2:-start}"
PLUGIN_PATH="homelander/_home/.vim/pack/datfinesoul/${METHOD}/${TARGET}"
#BRANCH="upgrade-${TARGET}"

if [[ ! "${METHOD}" =~ ^(start|opt)$ ]]; then
  echo "invalid option: ${METHOD}"; false
fi

pwd
if [[ "$(git branch --show-current)" == "main" ]]; then
  echo "cannot work in main branch"; false
fi

#git status --short --untracked-files=normal
#git fetch --all
#git branch -b "upgrade-${TARGET}" origin/main

if [[ -d "${PLUGIN_PATH}" ]]; then
  rm -rf "${PLUGIN_PATH}"
  git commit -am "remove old ${TARGET} vim plugin"
fi
git sba "${REPO}" "${PLUGIN_PATH}"

# generate a patch
# git format-patch -1 695b2679 -o patches/
git am patches/* || git am --skip
