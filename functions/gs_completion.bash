_gs_completion() {
    # Get available commands by calling gs() and parsing output
    local commands
    commands=$(gs 2>/dev/null | grep "^→" | sed 's/^→ \([^ ]*\).*/\1/')
    
    # COMPREPLY is a predefined bash variable that the completion system expects to find in ALL CAPS.
    # COMP_WORDS - array of all words on command line
    COMPREPLY=($(compgen -W "$commands" -- "${COMP_WORDS[COMP_CWORD]}"))
}

# Register the completion
complete -F _gs_completion gs