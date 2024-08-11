## Overview

A collections of things to get my terminal up and running in a fairly consistent state

## Install

### Core

```bash
git clone https://github.com/datfinesoul/env-ubuntu.git
cd env-ubuntu
./bootstrap.new.bash
```

## `gh` CLI

```bash
gh auth login
```

When asked to enter a "Title for your SSH key", please add something meaningful after the default of `GitHub CLI`

```
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations on this host? SSH
? Generate a new SSH key to add to your GitHub account? Yes
? Enter a passphrase for your new SSH key (Optional):
? Title for your SSH key: GitHub CLI
? How would you like to authenticate GitHub CLI? Login with a web browser

! First copy your one-time code: 46C9-00D4
Press Enter to open github.com in your browser...
Gtk-Message: 14:07:47.290: Failed to load module "canberra-gtk-module"
Gtk-Message: 14:07:47.291: Failed to load module "canberra-gtk-module"
[0806/140747.336375:WARNING:chrome_main_linux.cc(80)] Read channel stable from /app/extra/CHROME_VERSION_EXTRA
[0806/140747.469930:WARNING:chrome_main_linux.cc(80)] Read channel stable from /app/extra/CHROME_VERSION_EXTRA
Opening in existing browser session.
✓ Authentication complete.
- gh config set -h github.com git_protocol ssh
✓ Configured git protocol
✓ Uploaded the SSH key to your GitHub account: /home/philip.hadviger/.ssh/id_ed25519.pub
✓ Logged in as datfinesoul
```
