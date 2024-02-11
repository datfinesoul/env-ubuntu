#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "${script_dir}" != "$(readlink -e -- "$(pwd)")" ]]; then
  echo "please execute this script from its own directory"
  exit 1
fi

if [[ "${kernel_name}" == 'Darwin' ]]; then
  FILE_NAME='bashrc-apply.bash'
  touch "${HOME}/.bash_profile"
  # remove section in .bash_profille ( eg. #:somefile.bash:[+-] )
  sed -i '/#:'"${FILE_NAME}"':[+]/,/#:'"${FILE_NAME}"':[-]/d' "${HOME}/.bash_profile"
  # add the section back
  {
    echo "#:${FILE_NAME}:+"
cat << DOC
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
DOC
    echo "#:${FILE_NAME}:-"
  } >> "${HOME}/.bashrc"
fi

for FILE in bashrc/*.bash; do
  FILE_NAME="$(basename "${FILE}")"
  # remove section in .bashrc ( eg. #:somefile.bash:[+-] )
  sed -i '/#:'"${FILE_NAME}"':[+]/,/#:'"${FILE_NAME}"':[-]/d' "${HOME}/.bashrc"
  # add the section back
  {
    echo "#:${FILE_NAME}:+"
    cat "${FILE}"
    echo "#:${FILE_NAME}:-"
  } >> "${HOME}/.bashrc"
done
