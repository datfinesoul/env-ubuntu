#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

if [[ "$(uname -s)" == "Darwin" ]]; then
	exit 0
	mkdir -p "$HOME/Library/KeyBindings"
	cat > "$HOME/Library/KeyBindings/DefaultKeyBinding.dict" <<-'EOF'
	{
	/* Remap Home / End keys to be correct */
	"\UF729" = "moveToBeginningOfLine:"; /* Home */
	"\UF72B" = "moveToEndOfLine:"; /* End */
	"$\UF729" = "moveToBeginningOfLineAndModifySelection:"; /* Shift + Home */
	"$\UF72B" = "moveToEndOfLineAndModifySelection:"; /* Shift + End */
	"^\UF729" = "moveToBeginningOfDocument:"; /* Ctrl + Home */
	"^\UF72B" = "moveToEndOfDocument:"; /* Ctrl + End */
	}
	EOF
	pass "OSX keybindings configured"
else
	info "Darwin only - skipping"
fi

# vim: set ft=bash :
