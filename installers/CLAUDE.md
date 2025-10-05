# Installers Directory

This directory contains installation scripts for development tools, cloud utilities, and system packages.

## Script Types

**Automatic installers** (`*.auto.bash`):
- Run automatically during bootstrap
- Examples: `1_core.auto.bash`, `gh.auto.bash`, `starship.auto.bash`, `fzf.auto.bash`

**Manual installers** (`*.manual.bash`):
- Run on-demand by user
- Examples: Docker, Git, Golang, NVM, AWS CLI, Terraform, OpenTofu, SAM CLI, Bitwarden, security tools

## Core Components

**`_core.bash`**: Shared library providing:
- Logging functions: `info`, `debug`, `pass`, `warn`, `fail`
- System detection: `kernel_name`, `machine`, `architecture`
- Installation tracking via cache mechanism
- Error handling and cleanup
- Process safety (prevents root execution)

## Cache Mechanism

**Location**: `installers/cache/`

**Purpose**: Tracks successful installations via empty marker files (`*.done`)

**Behavior**:
- Before running, checks for `cache/${install_name}.done`
- If exists: skips installation (idempotent)
- If missing: proceeds with installation
- On success: creates marker file

**Override**: Use `--force` flag to ignore cache and reinstall

**Implementation**: See `_core.bash:122-145`

## Other Directories

**`legacy/`**: Deprecated installer scripts
**`patch/`**: Patch files for specific installations

## Execution

All scripts inherit strict bash mode from `_core.bash`:
```bash
set -o errexit -o nounset -o pipefail -o errtrace
```

All operations log to `/tmp/${install_name}.log`
