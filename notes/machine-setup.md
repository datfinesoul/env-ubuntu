# Machine Setup

Steps for a host that has no profile yet. The shared tree and the render base already work. A profile adds the Pi keys and the local files that one host needs.

## New profile

1. Add `homelander/_machines/<name>/_patch/.pi/agent/settings.json` with the Pi keys for that host.
2. Add `homelander/_machines/<name>/_home/` only for files that exist on that host alone.
3. Install `jq`. The Linux package list and `mac-bootstrap.bash` include it.
4. On macOS, install GNU `readlink` and `sed`. `_core.bash` maps them to `greadlink` and `gsed`, and `mac-bootstrap.bash` installs `coreutils` and `gnu-sed`.
5. Run `ENV_UBUNTU_MACHINE=<name> ./bootstrap.bash`. Later runs read `~/.config/env-ubuntu/machine`.
6. Restart Pi, then run `color-theme <name>`.

A host without a profile stops bootstrap at `pi-settings.bash`. The error lists the profiles that exist.

## work-mac

1. Add `homelander/_machines/work-mac/_home/.my_profiles.json`. Copy the Dell file and keep only the names this host uses. Without this file, `~/.my_profiles.json` stays a dangling link and `profile` fails.
2. Run `./pi-settings.bash --machine work-mac`. The render replaces the dangling settings link with a real file.
3. Run `./homelinker.bash` to link the overlay.
4. Restore the theme with `color-theme remarkable` or `color-theme default`.
5. Restart Pi.

`./bootstrap.bash` runs steps 2 and 3 after it asks for the machine. The patch carries `npm:@grafana/agento11y-pi`, so confirm that package belongs on this host. The patch sets no `npmCommand`, so this host uses npm and the Dell host uses pnpm.

## home-desktop-linux

The host is a fresh Ubuntu 26.04.1 machine with no old links.

1. Run `ENV_UBUNTU_MACHINE=home-desktop-linux ./bootstrap.bash`.
2. Run `color-theme remarkable` or `color-theme default`.
3. Restart Pi.

The profile copies the Dell Pi keys and uses pnpm. Its `_home/.my_profiles.json` lists `glg` and `personal`. Edit that file if the desktop needs other names.

## Not verified

- No macOS run of `render.bash`, `pi-settings.bash`, or `homelinker.bash`.
- No first bootstrap on `work-mac` or `home-desktop-linux`.
- `installers/` package names on Ubuntu 26.04.1.
