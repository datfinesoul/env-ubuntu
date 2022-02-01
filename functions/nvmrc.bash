nvmrc () {
  # swtich to the nodejs version automatically, if an .nvmrc file is found in the current dir.
  [[ -f .nvmrc ]] || return 0
  local CURRENT DESIRED
  CURRENT="$(node -v)"
  CURRENT="${CURRENT//[$'\r\t\n v']}"
  DESIRED="$(<.nvmrc)"
  DESIRED="${DESIRED//[$'\r\t\n v']}"
  if [[ -z "${CURRENT}" || -z ${DESIRED} ]]; then
    return 0
  fi
  if [[ \
    "${DESIRED}" != "${CURRENT}" \
    && "${DESIRED}" != "${CURRENT%.*}" \
    && "${DESIRED}" != "${CURRENT%%.*}" \
    ]]; then
      nvm use "${DESIRED//[$'\r\t\n v']}"
      echo
  fi
}
