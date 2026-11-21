## Overview

A collections of things to get my terminal up and running in a fairly consistent state

## Install

### Core

```bash
git clone https://github.com/datfinesoul/env-ubuntu.git
cd env-ubuntu
./bootstrap.bash
```

### Machine profile

`bootstrap.bash` renders `~/.pi/agent/settings.json` from `homelander/_render/`
plus one machine patch under `homelander/_machines/`.

Select the machine with `--machine`, `ENV_UBUNTU_MACHINE`, or
`~/.config/env-ubuntu/machine`. `bootstrap.bash` asks for a profile when none of
those is set. Without a profile the render fails and lists the available
profiles.

```bash
./pi-settings.bash --machine dell-laptop-linux
```

`homelinker.bash` links `_machines/<name>/_home/` after the shared tree, so a
machine entry wins for the path it covers.

Run `./test/run.bash` after you change the render or link scripts.

## Patches

`patches/` holds `git format-patch` exports of edits that must survive a re-sync of vendored content under `homelander/_home/`.

- `0001-monkeypatch-json-inline-problem.patch` comments out `runtime! ftplugin/json.vim` in `vim-polyglot/syntax/json.vim`. See [elzr/vim-json#42](https://github.com/elzr/vim-json/issues/42).

The edit is already in the tracked file. Read the patch only when you replace vim-polyglot with `git subtree`, then make the same edit by hand. The patch uses the old `home/` paths, so `git am` and `git apply` fail on the current tree.

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
