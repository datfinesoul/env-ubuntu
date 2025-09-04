# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Ubuntu environment setup repository containing bash scripts to bootstrap and configure a consistent terminal environment. The repository focuses on automated installation of development tools and environment configuration.

## Commands

### Initial Setup
```bash
./bootstrap.bash
```
Main bootstrap script that must be run from the repository directory. Sets up the entire environment including installing packages and configuring dotfiles.

### Manual Installers
Individual installers in `installers/` directory can be run manually:
```bash
./installers/[tool].manual.bash
```

## Architecture

### Core Components

**Core Libraries**
- `_core.bash`: Shared library providing logging functions (`info`, `debug`, `pass`, `warn`, `fail`), system detection, and common utilities
- `core.source`: Entry point validation and basic setup (cannot be called directly)

**Bootstrap System**
- `bootstrap.bash`: Main entry point that orchestrates the setup process
- Automatically runs all `*.auto.bash` installers in the `installers/` directory
- Sets up `ENV_UBUNTU_ROOT` environment variable and integrates with home directory

**Directory Structure**
- `installers/`: Contains both automatic (`*.auto.bash`) and manual (`*.manual.bash`) installation scripts
- `homelander/`: Contains dotfile configurations that get linked to the home directory  
- `bin/`: Utility scripts including Git batch operations and profile management tools
- `functions/`: Shell function definitions for common operations

### Installation System

**Automatic Installers** (run during bootstrap):
- Core packages (`1_core.auto.bash`)
- GitHub CLI (`gh.auto.bash`) 
- Starship prompt (`starship.auto.bash`)
- FZF fuzzy finder (`fzf.auto.bash`)

**Manual Installers** (run on demand):
- Development tools: Docker, Git, Golang, Node.js/NVM
- Cloud tools: AWS CLI, Terraform, OpenTofu, SAM CLI
- Security tools: Bitwarden, Granted CLI, IAMLive
- Utilities: Various CLI tools and applications

### Key Features

- **Cross-platform support**: Detects Darwin (macOS) vs Linux and adjusts behavior
- **Architecture detection**: Handles both amd64 and arm64 architectures
- **Comprehensive logging**: All scripts log to `/tmp/` with detailed success/failure reporting
- **Safety checks**: Prevents running as root, validates execution context
- **Dotfile management**: Automated linking of configuration files to home directory

### Error Handling

All scripts follow bash strict mode (`set -o errexit -o nounset -o pipefail -o errtrace`) and include comprehensive error trapping with cleanup functions.