function export-json-to-env () {
    INPUT_FILE="${1}"
    while IFS=$'\t\n' read -r LINE; do
        export "${LINE}"
    done < <(
        <"${INPUT_FILE}" jq \
            --compact-output \
            --raw-output \
            --monochrome-output \
            --from-file \
            <(echo 'to_entries | map("\(.key)=\(.value)") | .[]')
    )
}
