#!/usr/bin/env bash
DOTFILE="${1}"
TARGET="${HOME}/.${DOTFILE}"
for FILE in "dotloader/${DOTFILE}"/*.bash; do
  # skip if there are no files
  [[ -f "${FILE}" ]] || continue
  FILE_NAME="$(basename "${FILE}")"
  # remove section ( eg. #:somefile.bash:[+-] )
  touch "${TARGET}"
  sed -i '/#:'"${FILE_NAME}"':[+]/,/#:'"${FILE_NAME}"':[-]/d' "${TARGET}"
  # add the section back
  {
    echo "#:${FILE_NAME}:+"
    cat "${FILE}"
    echo "#:${FILE_NAME}:-"
  } >> "${TARGET}"
done
