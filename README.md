## Overview

A collections of things to get my terminal up and running in a fairly consistent state

## Install

### Core

```bash
git clone https://github.com/datfinesoul/env-ubuntu.git
cd env-ubuntu
./bootstrap.bash
```

## `gh` CLI

```bash
gh auth login
```

When asked to enter a "Title for your SSH key", please add something meaningful after the default of `GitHub CLI`

```text
? What account do you want to log into? GitHub.com
? What is your preferred protocol for Git operations on this host? SSH
? Generate a new SSH key to add to your GitHub account? Yes
? Enter a passphrase for your new SSH key (Optional):
? Title for your SSH key: GitHub CLI
? How would you like to authenticate GitHub CLI? Login with a web browser

! First copy your one-time code: 46C9-00D4
Press Enter to open github.com in your browser...
Opening in existing browser session.
✓ Authentication complete.
- gh config set -h github.com git_protocol ssh
✓ Configured git protocol
✓ Uploaded the SSH key to your GitHub account: /home/philip.hadviger/.ssh/id_ed25519.pub
✓ Logged in as datfinesoul
```

## Notes

### Apple Keyboard

- https://www.hashbangcode.com/article/turning-or-fn-mode-ubuntu-linux

| Value | Function | Description |
| - | - | - |
| 0 | disabled | Disables the 'fn' key. This means that pressing F2 will trigger F2 to be pressed and not the special action key. Pressing 'fn' + F2 will just press the F2 key as normal. |
| 1 | fkeyslast | Function keys are used as the last key. Pressing F2 will act as the special key. Pressing 'fn' + F2 will trigger F2. |
| 2 | fkeysfirst | Function keys are used as the first key. Pressing F2 will act as triggering F2. Pressing 'fn' + F2 will act as the special key. |

```bash
echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode
```

### GTK

```log
Gtk-Message: 19:46:44.146: Not loading module "atk-bridge": The functionality is provided by GTK natively. Please try to not load it.
```

```bash
# GTK_MODULES=gail:atk-bridge
unset GTK_MODULES
```
