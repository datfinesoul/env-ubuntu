for FILE in ~/env-ubuntu/functions/*.bash; do
  if [[ -f "${FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${FILE}"
  fi
done
