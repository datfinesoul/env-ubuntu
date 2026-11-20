# Homelinker Redesign v3 — Handoff and Leftovers

Status: handoff note. `voight2.md` holds the design and the phase plan. This file records the current state, the steps for another machine, and the work that remains.

## 1. Current state

The repository separates shared intent, machine intent, and local or runtime state.

| Tree | Owner | Deployment |
| - | - | - |
| `homelander/_home/` | repo, shared | symlink into `$HOME` |
| `homelander/_render/` | repo, shared | rendered into a real file |
| `homelander/_machines/<name>/_home/` | repo, one machine | symlink after the shared tree |
| `homelander/_machines/<name>/_patch/` | repo, one machine | merged over the render base |

Scripts:

- `bootstrap.bash` assembles the bash dotfiles, resolves the machine, renders the Pi settings, links the trees, then runs the installers.
- `homelander.bash` assembles a dotfile from `homelander/<dotfile>/` snippets.
- `homelinker.bash` links `_home` and the machine overlay. It links shared entries first, so a machine entry replaces a repository symlink. It never replaces a local file, and it never writes through a symlinked parent.
- `machine.bash` resolves the machine name and lists the profiles.
- `pi-settings.bash` declares the Pi settings mapping, renders the live file, and records the machine.
- `render.bash` merges a JSON base and a machine patch into an existing file.
- `test/run.bash` runs 64 checks with a temporary `$HOME`.

Machine identity comes from `--machine`, `ENV_UBUNTU_MACHINE`, then `~/.config/env-ubuntu/machine`. `bootstrap.bash` asks for a profile when all three are empty.

Profiles:

- `dell-laptop-linux`: patch plus `_home` overlay.
- `work-mac`: patch only.
- `home-desktop-linux`: patch plus `_home` overlay, copied from the Dell.

Pi settings are rendered, not linked. `theme` and the runtime keys (`lastChangelogVersion`, `extensionChangelogVersions`) are never in a base or patch, so they stay in the live file.

Branch state: only `main` and `voight` remain, locally and on `origin`. No ref carries `homelander/_home/.vim/.vim`.

CI is not used. `.github/workflows/linter.yml.off` stays disabled.

## 2. Steps for another machine

1. Add a profile: `homelander/_machines/<name>/_patch/.pi/agent/settings.json` with that machine's Pi keys. Add `_home/` for files that exist on that machine only.
2. Install `jq`. The Linux package list and `mac-bootstrap.bash` already include it.
3. On macOS, install GNU `readlink` and `sed`. `_core.bash` maps `readlink` to `greadlink` and `sed` to `gsed`. `mac-bootstrap.bash` installs `coreutils` and `gnu-sed`.
4. Run `ENV_UBUNTU_MACHINE=<name> ./bootstrap.bash` on the first run. Later runs read `~/.config/env-ubuntu/machine`.
5. Restart Pi and run `color-theme <name>` after the first render.

A machine without a profile stops bootstrap at `pi-settings.bash`. The error lists the available profiles.

## 3. Machine leftovers

### work-mac

Do these steps on the Mac after the pull.

1. Add `homelander/_machines/work-mac/_home/.my_profiles.json` to the repository. Copy the Dell file and keep only the names that host uses. Without this file, `~/.my_profiles.json` stays a dangling link and the `profile` function fails.
2. Render the Pi settings with `./pi-settings.bash --machine work-mac`. The render replaces the dangling settings symlink with a real file and records the machine.
3. Link the trees with `./homelinker.bash`. It replaces the old `~/.my_profiles.json` link with the overlay file.
4. Restore the theme with `color-theme remarkable` or `color-theme default`. The old settings file is gone, so the render cannot keep the previous `theme` value.
5. Restart Pi.

Notes:

- The patch carries `npm:@grafana/agento11y-pi`. Confirm that package belongs on that host.
- The patch sets no `npmCommand`, so that machine uses npm. The Dell host uses pnpm.
- `./bootstrap.bash` also works. It asks for the machine and then runs steps 2 and 3.
- `~/.claude` app data stays untouched (D15).

### home-desktop-linux

This is a fresh Ubuntu 26.04.1 machine, so it has no old links to migrate.

1. Run `ENV_UBUNTU_MACHINE=home-desktop-linux ./bootstrap.bash`.
2. Run `color-theme remarkable` or `color-theme default`.
3. Restart Pi.

The profile copies the Dell Pi keys and uses pnpm. Its `_home/.my_profiles.json` lists `glg` and `personal`, copied from the Dell. Edit that file if the desktop needs other names.

### New machines

- Create the profile before bootstrap. A missing profile is a hard stop, by design.
- Run `./test/run.bash` after any script change.

## 4. Repo leftovers

- Legacy migration code: `is_managed_container` and the LEGACY MIGRATION branch in `homelinker.bash`. Remove after every machine has run the new scripts.
- No `doctor` or `--dry-run` view that lists what each path will become.
- No unlink or cleanup mode.
- No `capture` command. An intentional live change stays local until a human edits a base or a patch.
- No guard against committing secrets, tokens, or private profile names.
- Render delete policy is undefined. A key that leaves the base or a patch stays in the live file.
- Arrays replace. A machine patch that changes `packages` repeats the full list.
- Tests are Linux-only. They use `sha256sum` and GNU `stat -c`.
- WSL and Windows are out of scope until someone needs them.
- `main` is the older branch. Merging `voight` into `main` is still a decision.
- A later `git merge origin/main` will report modify/delete conflicts on the retired Claude paths and the old Pi settings file. Keep them deleted.

## 5. Verification

Verified on `dell-laptop-linux`:

- `./test/run.bash` passes 64 checks.
- `pi-settings.bash` renders once and reports `unchanged` on the next run.
- `color-theme remarkable` leaves `git status` clean.
- The machine overlay link for `.my_profiles.json` replaces the shared link.
- `homelinker.bash` exits 0 on a second run.

Not verified:

- A full Pi restart against the rendered settings file.
- Any macOS run of `render.bash`, `pi-settings.bash`, or `homelinker.bash`.
- The first bootstrap on `work-mac`.
- The first bootstrap on `home-desktop-linux`.
- Ubuntu 26.04.1 package names in `installers/`. The repository targets current Ubuntu releases.

## 6. Decision index

`voight2.md` section 9 holds the full list. The decisions that shape the code:

- D6: never symlink a file that an app rewrites.
- D7: managed keys win, unmanaged keys survive.
- D8: machine entries link after shared entries.
- D16: git config uses `~/` paths and no writer, not a render.
- D17: `render.bash` takes explicit arguments. `pi-settings.bash` declares the mapping.
- D18: machine identity precedence with a prompt in bootstrap.
- D19: `theme` stays local.
- D20: the machine overlay links after the shared tree.
- D21: `.my_profiles.json` is machine-scoped.
- D22: AWS Assume policy stays machine-local.
