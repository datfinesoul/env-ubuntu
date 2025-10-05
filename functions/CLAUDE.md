# Functions Directory - CLAUDE.md

This file provides guidance for working with shell functions in this directory.

## Overview

The `functions/` directory contains bash function definitions that **must modify the current shell's environment**. These functions are loaded into the shell session and can change environment variables, current directory, shell options, or other shell state.

## Key Distinction: Functions vs Scripts

**Functions** (in this directory) are used when the tool MUST:
- Set or modify environment variables in the current shell
- Change the current working directory (`cd` commands)
- Provide shell completion functionality
- Create aliases or modify shell behavior
- Persist changes that affect the active shell session

**Scripts** (in `../scripts/` directory) are used when:
- The tool performs standalone operations without affecting shell state
- The utility processes data or performs operations that return results
- The tool should be composable with other command-line tools
- No need to modify the calling shell's environment

## Current Functions (Environment Modifying)

### AWS Environment Functions
- **`aws-assume.bash`** - Sets AWS environment variables (AWS_ACCESS_KEY_ID, etc.) in current shell *(Function: modifies shell environment)*
- **`aws-clear-env.bash`** - Unsets AWS environment variables from current shell *(Function: modifies shell environment)*
- **`aws-csm.bash`** - Sets AWS CSM and proxy environment variables *(Function: modifies shell environment)*
- **`aws-sso-creds.bash`** - Sets AWS SSO credentials as environment variables *(Function: modifies shell environment)*  
- **`awslogin.bash`** - Sets AWS authentication environment variables *(Function: modifies shell environment)*

### Development Environment Functions
- **`ccode.bash`** - Sets environment variables and launches Claude Code *(Function: modifies shell environment)*
- **`claude-p.bash`** - Sets environment variables for Claude Code *(Function: modifies shell environment)*
- **`nvmrc.bash`** - Switches Node.js versions using nvm *(Function: modifies shell environment)*
- **`profile.bash`** - Sets profile environment variables (MY_PROFILE, BW_SESSION) *(Function: modifies shell environment)*

### Directory Navigation Functions
- **`gcd.bash`** - Changes directory within Git repository with completion *(Function: changes current directory)*
- **`gs.bash`** + **`gs_completion.bash`** - Enhanced Git status with directory navigation and completion *(Function: integrates with shell completion)*

### Environment Integration Functions
- **`bw-env.bash`** - Sets Bitwarden session environment variables *(Function: modifies shell environment)*
- **`export-json-to-env.bash`** - Exports JSON key-value pairs as environment variables *(Function: modifies shell environment)*
- **`coauthor.bash`** - Git workflow integration with environment context *(Function: integrates with Git workflow)*

## Migrated to Scripts

The following functions were moved to `../scripts/` because they don't need to modify shell state:

**Standalone Utilities:** aws-decode-message, aws-delete-secret-permanently, aws-fingerprint, changelog, csv-to-markdown, epoch, git-branch-age, git-branch-clean, git-check-access, git-track, iamlive-nointernet, ipv6, logging, make-token, myip, onoff, perform-home-backup, random-string, relpath, tls-check-expiration

## Function Loading

Functions are loaded into the shell environment through the bash configuration system in `homelander/.bashrc/`. They become available as shell commands after the environment is set up.

## Adding New Functions

**Important:** Only add functions to this directory if they MUST modify the shell environment. If the utility can work as a standalone script, put it in `../scripts/` instead.

When creating new shell functions:

1. **File naming**: Use descriptive names ending in `.bash`
2. **Function definition**: Define functions with clear, descriptive names
3. **Aliases**: Create aliases for common function names (e.g., `alias aws-assume=aws_assume`)
4. **Documentation**: Include inline comments explaining why this needs to be a function
5. **Error handling**: Use `return` (not `exit`) for error conditions
6. **Dependencies**: Check for required tools/commands before using them
7. **Environment focus**: Clearly document what shell environment changes the function makes

## Function Patterns

Common patterns used in these functions:

### Tool Availability Check
```bash
# Exit if required tool isn't available
if ! type git &> /dev/null; then return 1; fi
```

### Git Repository Validation
```bash
# Get git top level directory or exit if not in repo
local tld
tld="$(git rev-parse --show-toplevel 2> /dev/null)" || return 1
```

### Environment Variable Management
```bash
# Set environment variables in current shell
export AWS_ACCESS_KEY_ID="$access_key"
export AWS_SECRET_ACCESS_KEY="$secret_key"

# Unset environment variables from current shell
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

### Directory Navigation
```bash
# Change directory in current shell (functions only!)
cd "$target_directory" || return 1
```

## Testing Functions

To test functions during development:
1. Source the function file: `source functions/[function-name].bash`
2. Call the function directly to test behavior
3. Check return codes and error handling
4. Test with various input scenarios

## Security Considerations

- Functions handling credentials should never log sensitive data
- AWS functions should properly manage temporary credentials
- Git functions should validate repository access before operations
- Always validate inputs, especially for functions that modify system state

## Integration Notes

These functions integrate with:
- The main bash environment through `homelander/.bashrc/` loading
- Shell environment variable management
- Directory navigation and Git workflows
- Development tool environment setup (Node.js, AWS, etc.)
- Interactive shell completion systems

Functions are designed to modify and enhance the current shell session, providing persistent environment changes that affect subsequent commands in the same terminal session.

## Why These Remain Functions

Each function in this directory serves a specific purpose that requires shell environment modification:

- **AWS functions**: Must set environment variables for subsequent AWS CLI commands
- **Directory navigation**: Must change the current working directory of the shell
- **Development environment**: Must switch tool versions or set environment variables that persist
- **Shell completion**: Must integrate with bash completion system
- **Environment integration**: Must export variables or modify shell state for other tools

If a utility doesn't need to modify the shell environment, it belongs in `../scripts/` as a standalone executable.