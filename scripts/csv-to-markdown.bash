#!/usr/bin/env bash

alias csv-to-markdown=csv_to_markdown
# Function to convert CSV to Markdown Table
csv_to_markdown() {
	  # Read the header and create the Markdown table header
    read header
    header=$(echo $header | awk -F, '{ for (i=1; i<=NF; i++) gsub(/"\\""/, "", $i); for (i=1; i<=NF; i++) printf "| %s ", $i; print "|"; }')
    separator=$(echo $header | awk -F'|' '{ for (i=2; i<NF; i++) printf "|---"; print "|"; }')

    # Output the table header and separator
    echo "$header"
    echo "$separator"

    # Output the table rows
    while IFS= read -r line; do
        echo "$line" | awk -F, '{ gsub(/"\\""/, "", $0); printf "|"; for (i=1; i<=NF; i++) printf " %s |", $i; print ""; }'
    done
}

# Call the function with all arguments
csv_to_markdown "$@"
