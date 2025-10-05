#!/usr/bin/env bash

relpath () {
  local POS REF DOWN
  POS="${1%%/}"
  REF="${2%%/}"
  DOWN=''

  while :; do
    test "${POS}" = '/' && break
    case "${REF}" in
      ${POS}/*)
        break
        ;;
    esac
    DOWN="../${DOWN}"
    POS=${POS%/*}
  done

  echo "${DOWN}${REF##${POS}/}"
}

# Call the function with all arguments
relpath "$@"
