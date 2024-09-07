onoff () {
	local filename="$1"
	local base="${filename%.*}"
	local extension="${filename##*.}"

	if [[ "$extension" == "off" ]]; then
		# If the file ends with .off, remove the .off
		mv "$filename" "$base"
	else
		# If the file does not end with .off, add .off
		local new_filename="${filename}.off"
		mv "$filename" "$new_filename"
	fi
}
