#!/usr/bin/env bash
info () { test ! -t 0 && >&2 sed "s|^|:: ${1:-}|g" || >&2 echo -e ":: $*"; }
pass () { test ! -t 0 && >&2 sed "s|^|:✔ ${1:-}|g" || >&2 echo -e ":✔ $*"; }
fail () { test ! -t 0 && >&2 sed "s|^|:✖ ${1:-}|g" || >&2 echo -e ":✖ $*"; }
# Sourced scripts, can use 'return'. In order to not exit the sourced script
#   the 'return test' happens in a subshell
(return 0 2>/dev/null) && sourced=1 || sourced=0
if [[ "${sourced}" -eq 0 ]]; then
  fail "_core.bash should be sourced"
  exit 1
fi

kernel_name="$(uname -s)" # Darwin/Linux
machine="$(uname -m)"
if [[ "${machine}" == "x86_64" ]]; then
  architecture="amd64"
else
  architecture="arm64"
fi

info "K:${kernel_name}"
info "M:${machine}"
info "A:${architecture}"

if [[ "$(uname -s)" == "Darwin" ]]; then
  function readlink {
    greadlink "$@"
  }
  export -f readlink

  function sed {
    gsed "$@"
  }
  export -f sed
fi

script_path="$(readlink -e -- "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")"
script_name="$(basename "${script_path}")"
info "SP:${script_path}"
info "SN:${script_name}"
IFS=$'.' read -r install_name install_type <<< "${script_name%.bash}"
info "IN:${install_name}"
info "IT:${install_type}"

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

PID=$$
install_log="/tmp/${install_name}.log"

# log stdout/stderr to a file and stdout
exec &> >(tee "${install_log}")

function cleanup {
  # shellcheck disable=SC2154
  if [ -n "${1:-}" ]; then
    echo ":: ${install_name}:${PID} Aborted by ${1:-}"
  elif [ "${status}" -ne 0 ]; then
    echo ":: ${install_name}:${PID} Failure (status $status)"
  else
    echo ":: ${install_name}:${PID} Success"
  fi
}
export -f cleanup
trap 'status=$?; cleanup; exit $status' EXIT
trap 'trap - HUP; cleanup SIGHUP; kill -HUP $$' HUP
trap 'trap - INT; cleanup SIGINT; kill -INT $$' INT
trap 'trap - TERM; cleanup SIGTERM; kill -TERM $$' TERM

return 0




  script_name="$(basename "${CURRENT_SCRIPT}")"
  SCRIPT_DIR="${CURRENT_SCRIPT_DIR}"
  SCRIPT_FULL_PATH="${CURRENT_SCRIPT_DIR}/${script_name}"

  set +o allexport

  [[ -n "${script_name}" ]] && bash "${SCRIPT_FULL_PATH}" $@
fi
#!/usr/bin/env bash

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

kernel_name="$(uname -s)" # Darwin/Linux
machine="$(uname -m)"
if [[ "${machine}" == "x86_64" ]]; then
  architecture="amd64"
else
  architecture="arm64"
fi

# NOTE: sometimes you need ${kernel_name,,}
read -r VERSION URL <<< "$(gh api "/repos/${REPO}/releases/latest" \
  | jq \
  --arg k "${kernel_name}" \
  --arg a "${architecture}" \
  --arg m "${machine}" \
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

if [[ "${kernel_name}" == "Darwin" ]]; then
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
  architecture="$(dpkg --print-architecture)"
else
  >&2 echo ":: unsupported kernel"
fi

wget -q "https://github.com/nektos/act/releases/download/v${VERSION}/act_${KERNEL}_${HARDWARE}.tar.gz"
tar xzf act_${KERNEL}_${HARDWARE}.tar.gz
sudo mv "act" "${TARGET}"

# vi: set ft=bash :
