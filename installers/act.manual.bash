#!/usr/bin/env bash

source './_core.bash'

bla

exit 0


# full path to parent script
SCRIPT="$(readlink -e -- "${0}")"
# parent script file name
SCRIPT_BASE="$(basename "${SCRIPT}")"

# full path to this file
SOURCE_FILE="$(readlink -e -- "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")"
# directory of this file
SOURCE_DIR="$(dirname "${SOURCE_FILE}")"

if [[ "${SCRIPT_BASE}" == 'core.source' ]]; then
  echo ":: cannot call core.source directly"
  exit 1
fi

if [[ "$(id -u)" -eq "0" ]]; then
  echo "please DO NOT run as root";
  exit 1
fi

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

PID=$$
LOG="/tmp/${SCRIPT_BASE}.log"

# log stdout/stderr to a file and stdout
exec &> >(tee "${LOG}")

function cleanup {
  # shellcheck disable=SC2154
  if [ -n "${1:-}" ]; then
    echo ":: ${SCRIPT_BASE}:${PID} Aborted by ${1:-}"
  elif [ "${status}" -ne 0 ]; then
    echo ":: ${SCRIPT_BASE}:${PID} Failure (status $status)"
  else
    echo ":: ${SCRIPT_BASE}:${PID} Success"
  fi
}
export -f cleanup
trap 'status=$?; cleanup; exit $status' EXIT
trap 'trap - HUP; cleanup SIGHUP; kill -HUP $$' HUP
trap 'trap - INT; cleanup SIGINT; kill -INT $$' INT
trap 'trap - TERM; cleanup SIGTERM; kill -TERM $$' TERM
#!/usr/bin/env /usr/local/bin/env-ubuntu-core
# NOTE: OSX requires shebang to be binary file not script, this is the workaround
# shellcheck disable=SC1090
. "${SCRIPT_DIR}/core.source"

REPO="glg/gdsservice"

# Only change the above

KERNEL_NAME="$(uname -s)" # Darwin/Linux
MACHINE="$(uname -m)"
if [[ "${MACHINE}" == "x86_64" ]]; then
  ARCHITECTURE="amd64"
else
  ARCHITECTURE="arm64"
fi

# NOTE: sometimes you need ${KERNEL_NAME,,}
read -r VERSION URL <<< "$(gh api "/repos/${REPO}/releases/latest" \
  | jq \
  --arg k "${KERNEL_NAME}" \
  --arg a "${ARCHITECTURE}" \
  --arg m "${MACHINE}" \
  -r '[.tag_name, (.assets[].browser_download_url | select(test($k+"_"+$m)))] | @tsv' \
)"

ZIP_FILE="${URL##*/}"
EXECUTABLE="${REPO##*/}"
VERSIONED_EXE="${EXECUTABLE}_${VERSION}"

gh release download "${VERSION}" -R "${REPO}" -p "${ZIP_FILE}"

TARGET_DIR="${HOME}/.local/${EXECUTABLE}"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "${TARGET_DIR}"
mkdir -p "${BIN_DIR}"

tar -xf "${ZIP_FILE}"
#unzip "${ZIP_FILE}"

mv "${EXECUTABLE}" "${TARGET_DIR}/${VERSIONED_EXE}"

if [[ "${KERNEL_NAME}" == "Darwin" ]]; then
  ln -sf "${TARGET_DIR}/${VERSIONED_EXE}" "${BIN_DIR}/${EXECUTABLE}"
else
  ln --symbolic --force "${TARGET_DIR}/${VERSIONED_EXE}" "${BIN_DIR}/${EXECUTABLE}"
fi

# vim: set ft=bash :
#!/usr/bin/env /usr/local/bin/env-ubuntu-core
# NOTE: OSX requires shebang to be binary file not script, this is the workaround
# shellcheck disable=SC1090
. "${SCRIPT_DIR}/core.source"

VERSION="${1:-0.2.42}"
TARGET="/usr/local/bin/act"
KERNEL="$(uname -s)"
HARDWARE="$(uname -m)"

if [[ "${KERNEL}" == "Linux" ]]; then
  ARCHITECTURE="$(dpkg --print-architecture)"
else
  >&2 echo ":: unsupported kernel"
fi

wget -q "https://github.com/nektos/act/releases/download/v${VERSION}/act_${KERNEL}_${HARDWARE}.tar.gz"
tar xzf act_${KERNEL}_${HARDWARE}.tar.gz
sudo mv "act" "${TARGET}"

# vi: set ft=bash :
