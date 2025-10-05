# Scripts Directory - CLAUDE.md

This file provides guidance for working with standalone executable scripts in this directory.

## Overview

The `scripts/` directory contains standalone bash utilities that perform specific operations without needing to modify the current shell's environment. These are executable scripts (not shell functions) that can be run independently, used in pipelines, or called from other programs.

## Key Distinction: Scripts vs Functions

**Scripts** are used when:
- The utility performs operations or processes data without affecting shell state
- The tool could be useful outside of the current shell session
- The utility should be composable with other command-line tools
- No need to modify environment variables, current directory, or shell options

**Functions** (in `functions/` directory) are used when:
- The tool needs to modify the current shell's environment variables
- The tool needs to change the current working directory
- The tool provides shell completion or aliases
- The tool needs to persist changes in the active shell session

## Script Categories

### AWS Utilities
- `aws-decode-message.bash`: Decode AWS authorization error messages using STS
- `aws-delete-secret-permanently.bash`: Permanently delete AWS Secrets Manager secrets
- `aws-fingerprint.bash`: Generate certificate fingerprints for AWS resources

### Git Utilities
- `git-branch-age.bash`: Display the age of Git branches
- `git-branch-clean.bash`: Clean up merged or stale Git branches  
- `git-check-access.bash`: Verify access permissions to Git repositories
- `git-track.bash`: Set up branch tracking for Git repositories

### Data Processing & Conversion
- `csv-to-markdown.bash`: Convert CSV input to Markdown table format
- `changelog.bash`: Generate changelogs using GitHub API
- `epoch.bash`: Convert between Unix timestamps and human-readable dates

### Network & Security Tools
- `iamlive-nointernet.bash`: Run IAM Live monitoring without internet access
- `ipv6.bash`: IPv6 network configuration utilities (requires sudo)
- `myip.bash`: Retrieve public IP address from external services
- `tls-check-expiration.bash`: Check TLS certificate expiration dates

### System & Utility Tools
- `logging.bash`: Logging utilities for scripts (provides log_info, log_debug, etc.)
- `make-token.bash`: Generate random tokens for various purposes
- `onoff.bash`: File-based on/off state management utility
- `perform-home-backup.bash`: Home directory backup utility using rsync
- `random-string.bash`: Generate random strings with various options
- `relpath.bash`: Calculate relative paths between directories

## Usage Patterns

### Direct Execution
```bash
# Run a script directly
./scripts/epoch.bash 1631234567
./scripts/csv-to-markdown.bash < data.csv
./scripts/git-branch-age.bash
```

### Pipeline Usage
```bash
# Use in pipelines
cat data.csv | ./scripts/csv-to-markdown.bash > table.md
echo "1631234567" | ./scripts/epoch.bash
./scripts/myip.bash | tee current-ip.txt
```

### Integration with Other Tools
```bash
# Use with other command-line tools
git branch | ./scripts/git-branch-age.bash
find . -name "*.crt" | xargs ./scripts/tls-check-expiration.bash
```

## Adding New Scripts

When creating new scripts in this directory:

1. **File naming**: Use descriptive names ending in `.bash`
2. **Shebang**: Start with `#!/usr/bin/env bash`
3. **Function definition**: Define the main function with clear, descriptive names
4. **Function invocation**: End with a call to the main function: `function_name "$@"`
5. **Executable permissions**: Set with `chmod 755`
6. **Documentation**: Include comments explaining the script's purpose and usage

### Script Template
```bash
#!/usr/bin/env bash

# Description of what this script does
my_utility() {
    local input="$1"
    # Script logic here
    echo "Result: $input"
}

# Call the function with all arguments
my_utility "$@"
```

## Error Handling

Scripts should include proper error handling:
- Check for required dependencies before using them
- Validate inputs and provide meaningful error messages
- Use appropriate exit codes (0 for success, non-zero for errors)
- Include cleanup functions when dealing with temporary files

## Integration Notes

These scripts:
- Are standalone and don't require sourcing into the shell
- Can be called from any directory (use absolute paths when needed)
- Are suitable for use in cron jobs, other scripts, or automation
- Don't modify the calling shell's environment
- Can be used by other users or programs on the system

## Security Considerations

- Scripts that require elevated privileges (like `ipv6.bash`) should validate permissions
- Never log or expose sensitive data in script output
- Validate all inputs, especially when processing user-provided data
- Use secure temporary file creation when needed
- Scripts handling credentials should follow security best practices

## Migration from Functions

These scripts were migrated from the `functions/` directory because they:
- Don't need to modify shell environment variables
- Don't need to change the current working directory
- Perform standalone operations that return results
- Are more useful as composable command-line utilities

The original function definitions are preserved within each script for backward compatibility, but they now operate as standalone executables.