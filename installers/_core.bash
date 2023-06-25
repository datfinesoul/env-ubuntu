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

info "KN:${kernel_name}"
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
script_dir="$(dirname "${script_path}")"
info "SP:${script_path}"
info "SN:${script_name}"
info "SD:${script_dir}"
IFS=$'.' read -r install_name install_type <<< "${script_name%.bash}"
info "IN:${install_name}"
info "IT:${install_type}"

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

if [[ "$(id -u)" -eq "0" ]]; then
  fail "please DO NOT run as root";
  return 1
fi

pid=$$
workdir="/tmp/${install_name}"
install_log="/tmp/${install_name}.log"

# directory that keeps track of successful installs
cache_dir="${script_dir}/cache"
mkdir -p "${cache_dir}"
done="${cache_dir}/${install_name}.done"

# if app was successfully installed it is skipped on re-runs
if [[ "${1:-}" == "--force" ]]; then
  shift
elif [[ -f "${done}" ]]; then
  echo ":: ${install_name}:${pid} skip"
  exit 0
fi

# if we are re-running, delete the previous install working dir
[[ -d "${workdir}" ]] && rm -rf "${workdir}"

# log stdout/stderr to a file and stdout
exec &> >(tee "${install_log}")

function cleanup {
  if [ -n "${1:-}" ]; then
    echo ":: ${install_name}:${pid} Aborted by ${1:-}"
  elif [ "${status}" -ne 0 ]; then
    echo ":: ${install_name}:${pid} Failure (status $status)"
  else
    echo ":: ${install_name}:${pid} Success"
    touch "${done}"
  fi
  popd > /dev/null
}
export -f cleanup
trap 'status=$?; cleanup; exit $status' EXIT
trap 'trap - HUP; cleanup SIGHUP; kill -HUP $$' HUP
trap 'trap - INT; cleanup SIGINT; kill -INT $$' INT
trap 'trap - TERM; cleanup SIGTERM; kill -TERM $$' TERM

mkdir -p "${workdir}"
pushd "${workdir}" > /dev/null
