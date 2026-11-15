# Homelinker Redesign v2 — Discussion & Plan

Status: discussion draft. Supersedes `voight.md`; no implementation yet.

This version keeps every finding and decision from `voight.md`, then adds the
machine-to-machine configuration problem found by comparing this branch with
`main`. The short version: the current system mostly uses one mechanism —
symlink the repo file into `$HOME` — for three different kinds of state that
need different ownership:

1. **Shared intent** — the same on every machine.
2. **Machine intent** — intentionally different per machine.
3. **Runtime and local state** — written by apps and humans, never by git.

Machine differences are currently encoded in branches and commits. Because the
live files are symlinks into the checkout, changing branches changes the live
configuration. The redesign must separate those three kinds of state.

Recommended direction: keep `_home` for shared immutable links, add
`_machines/<machine>` for machine links and JSON patches, add `_render` for
mutable shared bases, and ignore generated and runtime files. Migrate one file
at a time; do not rewrite the working link behavior first.

---

## 1. Current State

### 1.1 `homelinker.bash` (current behavior)

- Sources `_core.bash` for logging and common setup.
- Walks `homelander/_home/` at depth 1.
- **Files**: symlinks `$HOME/<name>` -> `homelander/_home/<name>`.
- **Directories**: by default symlinks the whole directory.
- **Materialized directories** (`.config/env-ubuntu`, `.pi/agent`,
  `.pi/agent/themes`) are created as real directories under `$HOME`, then their
  children are linked individually, recursively. This lets repo files coexist
  with app-generated local files.
- Skips existing non-symlink targets: logs `fail "skip ..."` and continues.
- **Legacy migration**: if a real directory is a tree of links that all resolve
  inside the source, it is removed and replaced by one directory symlink. A
  directory containing any regular file, broken link, or outside link is
  preserved and skipped.

`voight.md` describes the older "always materialize directories at depth 1"
behavior. The current script links whole directories unless the directory is in
`materialized_directories`.

### 1.2 `homelander.bash` (current behavior)

- Takes a `<dotfile>` argument (e.g., `.bashrc`) and an optional `[target]`
  (defaults to `$HOME/<dotfile>`).
- Looks in `homelander/<dotfile>/` for `*.bash` snippet files.
- Strips `#[+]:label:` / `#[-]:label:` delimited sections from the target file
  (idempotent cleanup).
- Re-appends each `*.bash` file's contents (comments and blanks stripped)
  wrapped in those delimiters.
- Assembles a dotfile by concatenating snippets from a plugin directory.

### 1.3 `bootstrap.bash` invocations (current)

```bash
homelander.bash .bash_profile   # assembles $HOME/.bash_profile from snippets
homelander.bash .bashrc         # assembles $HOME/.bashrc from snippets
homelander.bash .bash_logout    # assembles $HOME/.bash_logout from snippets
homelinker.bash                 # symlinks homelander/_home/ contents into $HOME
```

`bootstrap.bash` also writes `ENV_UBUNTU_ROOT` into
`homelander/.bashrc/0-env-ubuntu-root.bash`, which is gitignored. That is an
existing example of a generated local file living inside a tracked tree.

### 1.4 Current live wiring (observed)

Examples from this machine:

```text
~/.pi/agent/settings.json   -> repo/homelander/_home/.pi/agent/settings.json
~/.claude/settings.json     -> repo/homelander/_home/.claude/settings.json
~/.gitconfig                -> repo/homelander/_home/.gitconfig
~/.config/kitty             -> repo/homelander/_home/.config/kitty
~/.vim/pack                 -> repo/homelander/_home/.vim/pack
```

Mixed directories are more complicated:

```text
~/.pi/agent/                real dir (materialized); auth, models, sessions, trust
                            coexist with linked settings/theme files
~/.config/env-ubuntu/       real dir (materialized); generated theme files
                            coexist with linked repo files
~/.claude/                  real dir with app state AND managed links
~/.vim/                     real dir with app state AND managed links
~/.prompts/                 legacy materialized dir with a managed file link
```

`~/.claude` and `~/.vim` are important: they contain local app state
(`.credentials.json`, `history.jsonl`, `sessions/`, `.netrwhist`, etc.) plus
managed symlinks. `is_managed_container` rejects them because of the local
files, so `homelinker` logs `skip` and stops deploying new managed entries into
those directories. The explicit `materialized_directories` list works, but it is
reactive and easy to forget.

### 1.5 Key facts from history

- The target has always been `$HOME` — never changed across the entire git
  history.
- The scripts have always been invoked separately with no shared orchestration.
- Machine-specific configuration has repeatedly been committed directly to
  tracked dotfiles.
- Generated theme outputs and runtime app state have been committed alongside
  source files.
- The repo now has several long-lived branches whose differences include
  machine configuration, not just feature work.

---

## 2. Problem Space

### 2.1 Deployment scenarios (from `voight.md`)

1. **Standalone files** (e.g., `.gitconfig`) — symlink the whole file, fully
   version controlled.
2. **Whole directories** (e.g., `.vim/pack/`) — symlink the entire directory,
   fully version controlled.
3. **Mixed directories** (e.g., `~/.config/opencode/`, `~/.claude/`) — some
   files are managed and versioned, the rest are local app state. Currently
   underserved because the materialized-directory list is manual and because
   any local file blocks a whole-directory link.
4. **Assembled files** (e.g., `.bashrc`) — compose a file from labeled snippets.

### 2.2 State-ownership scenarios (new)

5. **Machine-variant whole files** — the entire file is different per machine
   (e.g., a global AWS role library).
6. **Machine-variant structured files** — most keys are shared, a few are
   machine-specific (e.g., Pi provider/model list, Claude hooks).
7. **App-rewritten managed files** — the app writes to the same file that git
   manages (e.g., `settings.json`, changelog versions, Orca hooks).
8. **Generated local artifacts** — a script generates a file from a tracked
   template (e.g., `kitty-theme.conf`, `git-theme.gitconfig`).
9. **Runtime and ephemeral state** — auth tokens, sessions, caches, trust
   records, backups, model stores. Never versioned.
10. **Local preferences** — a human or app chooses a value on this host (theme,
    model, effort level). It should survive a re-render but does not need to be
    shared.
11. **Project-scoped configuration** — config that belongs to a project, not to
    `$HOME` (`.pi/aws-assume.json`, `.pi/settings.json`,
    `.claude/settings.local.json`).
12. **Secrets** — credentials, tokens, keys, profile names that must not be
    public. Never tracked, never rendered from the repo.

The current symlink-everything model handles 1, 2, and 4 well. It handles 3
partially. It handles 5–12 badly or not at all.

---

## 3. Evidence: What Actually Varies

### 3.1 Pi settings (`~/.pi/agent/settings.json`)

The file is a symlink directly into the repo. Pi writes to it, so its contents
change in the working tree. Comparing `main` with this branch:

| Key | `main` | this branch | Likely class |
| - | - | - | - |
| `defaultProvider` | `github-copilot` | `opencode-go` | machine |
| `defaultModel` | `gpt-6.1-sol` | `deepseek-v4.1-flash` | machine |
| `enabledModels` | 3 Copilot models | 3 different models | machine |
| `modelThinkingLevels` | Copilot levels | Copilot models absent; different levels | machine |
| `packages` | 2 packages | 6 packages | shared + machine |
| `npmCommand` | absent | `["pnpm"]` | machine |
| `theme` | `remarkable` | `remarkable` | local preference |
| `lastChangelogVersion` | `1.0.4` | `1.5.2` | runtime |
| `extensionChangelogVersions` | absent | present, including `../pi-*` local-checkout entries | runtime |
| `hideThinkingBlock`, `tuiMode`, `treeFilterMode`, `showCacheMissNotices`, `outputPad`, `markdown` | same | same | shared |

Two important details:

- `extensionChangelogVersions` contains entries for local checkouts such as
  `../pi-watch` and `../pi-aws-assume`. That is app/runtime state leaking into a
  tracked user config.
- `theme` is also written by the `color-theme` shell function. It is a local
  preference, not a shared setting.

### 3.2 Claude settings (`~/.claude/settings.json`)

Also a symlink into the repo. Comparing `main` with this branch:

| Key | `main` | this branch | Likely class |
| - | - | - | - |
| `model` | `opus[1m]` | absent | local preference |
| `theme` | `dark-daltonized` | `light-ansi` | local preference |
| `hooks` | absent | large Orca hook set for Windows/macOS/Linux | machine / app-managed |
| `statusLine` | absent | present | machine / app-managed |
| `permissions`, `env`, `includeCoAuthoredBy`, `cleanupPeriodDays`, `autoCompactEnabled` | present | present | shared |
| `settings.json.bak` | tracked | tracked | runtime |

The Orca hook commands are generated by an app. Hand-maintaining them in this
repo is the wrong layer unless we explicitly decide they are machine config.

### 3.3 Git config (`~/.gitconfig`)

The shared file contains host-specific absolute paths:

```ini
[core]
    excludesfile = /Users/phadviger/.gitignore_global
[commit]
    template = /home/philip.hadviger/.gitmessage
```

`~/.gitconfig.local` already exists on this machine and is already gitignored,
but the tracked `.gitconfig` does not include it. This is the cheapest existing
win: move host paths into the local file and include it.

### 3.4 Generated theme artifacts

`functions/color-theme.bash` writes four things:

```text
~/.config/env-ubuntu/color-theme          local theme choice
~/.config/env-ubuntu/kitty-theme.conf     generated from themes/kitty/*.conf
~/.config/env-ubuntu/git-theme.gitconfig  generated from themes/git/*.gitconfig
~/.pi/agent/settings.json                 mutates .theme (through the symlink)
```

Three of those are currently tracked (`color-theme`, `kitty-theme.conf`, and
`settings.json`). Running `color-theme` can therefore dirty the repo and commit
a local preference. The tracked `themes/` files are the real source;
`~/.config/env-ubuntu/` outputs are generated.

### 3.5 Pi AWS Assume

`pi-aws-assume` already has explicit layering:

| Layer | Location | Scope |
| - | - | - |
| Bundled | extension `config.json` | defaults |
| Global | `~/.pi/agent/aws-assume.json` | personal rule library |
| Project | `<project>/.pi/aws-assume.json` | project allowlist |

A project policy must explicitly exist and select rules; a global library alone
never enables access. This is exactly the kind of scope separation the home
config needs. Do not invent a parallel merge for it.

For this repo, there is no `.pi/aws-assume.json`, so the extension is disabled
here. That is a deliberate project-scope decision, not a bug in this repo. Add
a policy only if this repo needs AWS access. The global file is machine-local
and may contain private profile names.

### 3.6 Branch drift versus machine drift

`git diff main..HEAD` shows about 20 files, but they are not all machine drift.
Some are feature work that should merge to `main` and be shared:

- `starship.toml` custom repo-path modules
- `.vimrc` theme synchronization and truecolor support
- `kitty.conf` tab title and remote-control socket
- installers and scripts

Others are genuinely machine-specific:

- Pi provider/model/package choices
- Claude Orca hooks and status line
- Git absolute paths
- Theme outputs and local preferences

Classification test:

| Question | If yes |
| - | - |
| Would this value be wrong on another host? | Machine intent |
| Would this value be wrong after the app rewrites the file? | Runtime state |
| Would this value be wrong on a fresh checkout of `main`? | Feature drift — merge shared |
| Did a human choose this on this host only? | Local preference |

This distinction matters: putting feature work into machine profiles would
duplicate it forever and hide it from other machines.

---

## 4. Root Cause

1. **One mechanism for different ownership models.** A symlink says "the repo
   owns this file forever." That is true for `.vimrc`; it is false for
   `settings.json`.
2. **Machine identity is encoded in branches.** Checking out a branch changes
   live app configuration. Merging branches merges machine configs.
3. **Source and generated output are mixed.** `themes/` is source;
   `~/.config/env-ubuntu/*.conf` is output. Both are tracked.
4. **Runtime state is mixed with intent.** Changelog versions, trusted
   directories, auth, sessions, and model stores live next to managed keys.
5. **There is no inventory.** Nothing declares which paths are linked, rendered,
   generated, or ignored. The behavior is spread across `homelinker.bash`,
   `homelander.bash`, `bootstrap.bash`, `.gitignore`, and convention.
6. **Mixed directories are handled by a manual allowlist.** `~/.claude` and
   `~/.vim` already demonstrate what happens when the list is incomplete:
   the whole directory is skipped.
7. **Absolute paths leak into shared files.** `/Users/phadviger` and
   `/home/philip.hadviger` cannot be shared.
8. **Partial solutions exist but are not generalized.** `materialized_directories`,
   `.gitconfig.local`, `themes/` templates, gitignored generated bash snippets,
   and `ENV_UBUNTU_ROOT` all point in the right direction.

---

## 5. Design Principles

1. **Repo owns intent, not runtime.** If an app owns the file, do not symlink a
   repo file over it.
2. **One branch, many machines.** Machine differences live in machine profiles,
   not in `git checkout`.
3. **Classify before deploying.** Every managed path gets one strategy: link,
   overlay-link, assemble, render, include, generate, or ignore.
4. **Managed keys win; unmanaged keys survive.** A render must update only the
   keys the repo manages. Local preferences and runtime keys stay.
5. **Prefer app-native layering.** Use `[include]`, kitty `include`, bash
   snippet assembly, Vim `source`, and AWS Assume project/global rules before
   writing a custom merge.
6. **Machine profiles are minimal diffs.** A profile should contain only what
   differs, not a copy of the whole tree.
7. **No secrets, no absolute paths.** Use `~`, `$HOME`, and
   `ENV_UBUNTU_ROOT`.
8. **Conservative migration.** Never delete unrecognized local state. If a
   target is not a symlink into the repo, preserve it and report.
9. **Test with a temporary `$HOME`.** No test may write to the real home.
10. **Keep dependencies small.** Bash, git, and `jq` are already present. Do not
    add a templating engine unless the merge logic proves unmanageable.
11. **Generated files are reproducible.** They are not committed; they are
    recreated from tracked templates.
12. **One declaration point.** `bootstrap.bash` (or a single `homelander`
    orchestrator) declares the mappings and modes. No hidden conventions.

---

## 6. Proposed Model

### 6.1 Three layers

| Layer | Owner | Examples | Deployment |
| - | - | - | - |
| Shared | repo | `.vimrc`, `.bashrc` snippets, base16, shared packages | link or assemble |
| Machine | repo machine profile | Pi provider/model list, Claude Orca hooks, work git identity | overlay-link or JSON patch |
| Local/runtime | user, app, tools | theme choice, auth, sessions, changelog versions, generated palettes | preserve or ignore |

The repo tracks only the first two. The third is either ignored or preserved
inside a rendered file.

### 6.2 Deployment modes

| Mode | Input | Output | Ownership | Conflict behavior |
| - | - | - | - | - |
| `link` | shared tree | symlink | repo | skip non-symlink target |
| `overlay-link` | machine tree | symlink, after shared | repo | machine wins over shared |
| `assemble` | snippet directory | generated file with delimiters | repo-managed sections | replace managed sections |
| `render` | shared base + machine patch + existing target | real JSON file | repo-managed keys; app/local keys preserved | merge, never clobber unmanaged keys |
| `include` | shared file + local include | symlink + local file | repo shared; user local | missing local file is allowed |
| `generate` | tracked template | local file | tool | regenerate on demand |
| `ignore` | none | app-owned | app | never touch |

### 6.3 Proposed repository layout

```text
homelander/
  _home/                              # shared immutable entries -> link
    .bash_aliases
    .config/...
    .vimrc
  _render/                            # shared mutable bases -> render, never link
    .pi/agent/settings.json
    .claude/settings.json
  _machines/
    work-linux/
      _home/                          # machine immutable overlay -> link after shared
      _patch/                         # machine JSON patches over _render
        .pi/agent/settings.json
        .claude/settings.json
    home-linux/
      ...
    work-mac/
      ...
  .bashrc/                            # assembled snippets (existing)
  .bash_profile/
  .bash_logout/
```

Rules:

- A path may not exist in both `_home` and `_render`.
- For a rendered path, use `_patch`, not `_home`. `_home` is for immutable
  links only.
- `_machines/<machine>/_home` mirrors `$HOME` and only contains differences.
- `_machines/<machine>/_patch` mirrors `_render` and only contains changed keys.
- Paths that are generated or runtime are absent from the repo and covered by
  `.gitignore`.
- The machine tree is linked after the shared tree, so it wins for whole
  files/directories.
- If a machine overlay needs to add a file inside a shared directory, that
  directory must be materialized. The orchestrator should compute this from the
  union of shared and machine paths, not from a hand-maintained list.

### 6.4 Machine identity

Precedence, highest first:

1. `--machine <name>` command-line argument.
2. `ENV_UBUNTU_MACHINE` environment variable.
3. `~/.config/env-ubuntu/machine` local file (written on first successful
   bootstrap).
4. Hostname mapping, only if a profile with that exact name exists.

Rules:

- Use stable names (`work-linux`, `home-linux`, `work-mac`), not hostnames that
  change with DHCP or renaming.
- If no profile matches, fail with a list of available profiles. Do not guess.
- Warn if the profile name suggests an OS that does not match `uname -s`.
- Tests pass the machine explicitly.

### 6.5 Render contract

For JSON files:

```text
desired = deep_merge(base, machine_patch)   # patch wins; arrays replace
result  = deep_merge(existing_target, desired)
                                      # desired wins for managed keys;
                                      # existing-only keys are preserved
```

Consequences:

- A key present in `base` or `machine_patch` is **managed**. The repo owns it.
- A key absent from both is **unmanaged**. The app or user owns it.
- Runtime keys such as `lastChangelogVersion` and
  `extensionChangelogVersions` should not appear in `base` or `machine_patch`,
  so they survive in the target.
- `theme` should not be a managed key if `color-theme` owns it. Either leave it
  out, or have `color-theme` write the local theme choice and let the render
  apply it.
- Arrays replace by default. If a list must merge, define that explicitly for
  that key. Do not rely on deep-merge behavior for arrays.
- Removing a managed key needs an explicit policy. Options: support a `null`
  value as "delete", or maintain a small managed-key list. This is an open
  question.
- Write atomically (temp file in the same directory, then rename).
- Preserve the existing file mode; use `0600` for new files that could contain
  sensitive values.
- If the target is a symlink into the repo, replace it with a regular file
  during migration, after verifying the link points where expected.

For non-JSON files:

- Prefer an app-native include (`[include]`, kitty `include`, Vim `source`).
- If the app has no include mechanism, use a whole-file machine profile and
  copy it, or keep a single shared file.
- Do not build a generic TOML/INI merge until there is a second real use case.

### 6.6 Pi settings proposal

| Key(s) | Class | Handling |
| - | - | - |
| `hideThinkingBlock`, `tuiMode`, `treeFilterMode`, `showCacheMissNotices`, `outputPad`, `markdown` | shared | `_render/.pi/agent/settings.json` |
| `packages` | shared base, machine override | base list; machine patch may provide a full list |
| `npmCommand` | machine | machine patch |
| `defaultProvider`, `defaultModel`, `enabledModels`, `modelThinkingLevels` | machine | machine patch |
| `theme` | local preference | owned by `color-theme`; preserve or apply from local theme file |
| `lastChangelogVersion`, `extensionChangelogVersions` | runtime | never in base or patch; preserved in target |

`pi install` and Pi itself will still write the live file. After an intentional
package change, run a `capture`/`diff` command to update the base or machine
patch. Without that, the live change is local only. That is preferable to
committing app state by accident.

### 6.7 Claude settings proposal

| Key(s) | Class | Handling |
| - | - | - |
| `permissions`, `env`, `includeCoAuthoredBy`, `cleanupPeriodDays`, `autoCompactEnabled` | shared | `_render/.claude/settings.json` |
| `hooks`, `statusLine` | machine / app-managed | machine patch only if the repo is the source of truth; otherwise leave app-owned |
| `model`, `theme`, `effortLevel`, `tui` | local preference / machine | machine patch or local only |
| `settings.json.bak` | runtime | remove from tracking; gitignore |

Orca writes hooks into `settings.json`. If Orca is the source of truth, do not
manage `hooks` at all: the render merge preserves keys that are absent from
base/patch. If the repo must manage them, put the full hook object in the
machine patch and re-render after Orca updates.

### 6.8 Git config proposal

```ini
# ~/.gitconfig (shared, tracked)
[include]
    path = ~/.gitconfig.local

# ~/.gitconfig.local (machine-local, ignored)
[core]
    excludesfile = ~/.gitignore_global
[commit]
    template = ~/.gitmessage
```

Put `[include]` at the end so local values win for single-valued keys. Keep
shared aliases, delta settings, and behavior in `.gitconfig`. Keep host paths,
work identities, and signing keys in `.gitconfig.local` or an
`[includeIf "gitdir:..."]` file.

### 6.9 Generated theme proposal

- Keep `themes/kitty/*.conf` and `themes/git/*.gitconfig` as shared source.
- Move `~/.config/env-ubuntu/color-theme`, `kitty-theme.conf`, and
  `git-theme.gitconfig` out of git; add them to `.gitignore`.
- Let `color-theme` write those local files and update the live Pi settings.
- On a new machine, a missing theme file means "use default"; `color-theme`
  creates the rest.
- Do not let `bootstrap` overwrite an existing theme choice.

### 6.10 AWS Assume proposal

- Keep project policies (`.pi/aws-assume.json`) in their project repos. Do not
  centralize them in `env-ubuntu`.
- Treat `~/.pi/agent/aws-assume.json` as machine-local by default. It contains
  profile names and security rules; it is not ordinary dotfile content.
- If it must be versioned, store a non-secret template under
  `_machines/<machine>/.pi/agent/aws-assume.json` and seed it only when the
  target is missing. Never overwrite an existing policy.
- Never store credentials or tokens. The extension itself never writes policy
  files; keep that property.

---

## 7. Concrete Classification

| Path | Current deployment | What varies | Proposed class | Proposed handling |
| - | - | - | - | - |
| `~/.bashrc`, `.bash_profile`, `.bash_logout` | assembled | shared snippets, OS conditionals | assembled shared | keep; optional machine snippet dir |
| `~/.bash_aliases` | symlink | shared, OS conditionals | immutable shared | keep |
| `~/.gitconfig` | symlink | shared plus absolute paths | shared + machine paths | add `[include] ~/.gitconfig.local`; move host paths |
| `~/.gitconfig.local` | ignored local file | host paths, identities | machine local | keep ignored; seed only if missing |
| `~/.gitmessage` | symlink | shared | immutable shared | keep |
| `~/.my_profiles.json` | symlink | likely machine AWS profiles | machine (verify) | machine overlay or local ignore; check sensitivity |
| `~/.vimrc` | symlink | shared plus feature drift | immutable shared | keep |
| `~/.vim/` | real dir with legacy links | shared plus feature drift | immutable shared | materialize `.vim`; `.netrwhist` stays local |
| `~/.config/base16-shell/` | whole-dir link | shared | immutable shared | keep |
| `~/.config/bat/` | whole-dir link | shared | immutable shared | keep |
| `~/.config/coc/` | whole-dir link | shared; `memos.json` local | immutable shared | keep; memo file ignored |
| `~/.config/kitty/` | whole-dir link | shared; paths use `$HOME` | immutable shared | keep; use `include` for local overrides |
| `~/.config/starship.toml` | symlink | shared plus feature drift | immutable shared | keep; machine override via `STARSHIP_CONFIG` if needed |
| `~/.config/env-ubuntu/color-theme` | tracked symlink | local theme choice | local preference | gitignore; keep local |
| `~/.config/env-ubuntu/kitty-theme.conf` | tracked file | generated palette | generated | gitignore; regenerate |
| `~/.config/env-ubuntu/git-theme.gitconfig` | local real file | generated | generated | gitignore explicitly |
| `~/.pi/agent/settings.json` | symlink | shared + machine + runtime + local | mutable structured | render; no symlink |
| `~/.pi/agent/themes/` | materialized links | shared | immutable shared | keep |
| `~/.pi/agent/aws-assume.json` | untracked | machine security rules | machine local | keep local or seed from machine profile |
| `~/.pi/agent/auth.json`, `models-store.json`, `trust.json`, `sessions/`, `git/`, `extensions/` | untracked | runtime | runtime | ignore |
| `~/.claude/CLAUDE.md` | symlink in mixed dir | shared | immutable shared | materialize `.claude`; keep link |
| `~/.claude/settings.json` | symlink in mixed dir | shared + machine + local | mutable structured | render; no symlink; materialize `.claude` |
| `~/.claude/settings.json.bak` | tracked | runtime backup | runtime | remove from tracking; gitignore |
| `~/.claude/.credentials.json`, history, sessions, projects | untracked | runtime/secret | runtime/secret | ignore |
| `~/.terraformrc` | symlink | shared | immutable shared | keep |
| `~/.prompts/` | real dir with managed link (legacy) | shared | immutable shared | let the migration collapse it, or materialize it |
| `~/.local/run/kitty/pi-watch` | untracked socket | runtime | runtime | ignore |
| project `.pi/aws-assume.json`, `.pi/settings.json`, `.claude/settings.local.json` | per-project | project scope | project config | keep in each project; not home-managed |

Immediate stopgap while the redesign is pending: add `.claude` and `.vim` to
`materialized_directories`, and remove `settings.json.bak` from tracking. This
does not solve machine variation, but it stops new managed files from being
silently skipped.

---

## 8. Options Considered

### Option A: Keep branch-per-machine (status quo)

- **Pros**: complete isolation; no merge tooling; easy to experiment.
- **Cons**: shared changes must be merged or cherry-picked into every branch;
  checking out a branch changes live config; machine configs drift; conflicts
  are resolved in dotfiles; a new machine needs a new branch.
- **Verdict**: reject as the long-term model. Keep branches for feature work,
  not machine identity.

### Option B: Whole-file machine profiles only

- **Pros**: simple; works for any file type; easy to reason about; no merge
  code.
- **Cons**: duplicates shared content; drifts immediately; still wrong for
  app-mutated files if symlinked; a small difference forces a full copy.
- **Verdict**: use only for immutable files that genuinely differ in full, not
  as the general solution.

### Option C: Base + machine patch render (recommended for structured files)

- **Pros**: shared content stays in one place; machine differences are small and
  reviewable; existing target keys survive; testable with fixtures.
- **Cons**: needs `jq` merge logic and tests; array semantics need a policy;
  removing a managed key needs an explicit rule; apps can still write the live
  file.
- **Verdict**: recommended for `settings.json`-style files.

### Option D: Leave app configs unmanaged; seed only

- **Pros**: simplest ownership model; apps own their files; no clobbering.
- **Cons**: no version control or drift detection for important settings; new
  machines need manual setup; shared updates do not roll out.
- **Verdict**: acceptable fallback for files where the app is clearly the source
  of truth (Orca hooks). Not sufficient for the whole system.

### Option E: Adopt an existing dotfile manager

Tools such as chezmoi, yadm, or stow already support templates, machine
profiles, and encrypted secrets.

- **Pros**: mature; less custom code; built-in apply/diff/status concepts.
- **Cons**: new dependency and mental model; migration of the existing bash
  assembler and link logic; harder to preserve current snippet delimiters and
  materialized-directory behavior; secrets story still needs decisions.
- **Verdict**: keep as a fallback if the custom render logic grows too large.
  Do not adopt now without a separate evaluation.

### Option F: Environment-variable templating (`envsubst`)

- **Pros**: no JSON merge code; any text format works.
- **Cons**: JSON escaping and arrays are fragile; comments and formatting are
  lost; no safe preservation of unmanaged keys.
- **Verdict**: reject for structured config.

### Recommended shape

Use a hybrid:

- `link` for immutable shared files and directories.
- `overlay-link` for immutable machine files.
- `render` for mutable structured files.
- `include` where the app already supports it.
- `generate` plus `ignore` for outputs and runtime state.
- `assemble` for bash dotfiles, as decided in D1.

---

## 9. Decisions

### 9.1 Carried over from `voight.md` (agreed)

- **D1: Scenario 4 — keep the label/snippet approach.** The
  `#+:label:` / `#-:label:` delimiters work well. No changes needed.
- **D2: Repo structure — separate trees by linking strategy (Option D).**
  Directory placement declares intent. No magic marker files. Rejected
  alternatives: always file-level (misses new files in fully versioned dirs),
  `.gitignore`-based (wrong layer), sentinel marker files (hidden magic).
  `voight.md` proposed two trees; v2 extends this to shared (`_home`), render
  (`_render`), and machine (`_machines/<name>`) trees.
- **D3: Target mapping — pass source/target as CLI arguments (Option 4).**
  Script signature: `./script <strategy> <source_dir> <target_dir>`. No config
  files, no dotfiles, no target-path naming conventions. The orchestrator
  declares mappings explicitly. Source-tree placement still declares strategy
  under D2; D3 only rejects deriving the **target** path from a name or a
  config file. Deciding factor: testability with temp directories. Rejected:
  central config file, directory name as target path, `.target` dotfile per
  directory.

### 9.2 New (proposed, pending open questions)

- **D4: One branch, many machines.** Machine differences move from branches
  into machine profiles.
- **D5: Separate shared, machine, and local/runtime state.** The repo owns the
  first two only.
- **D6: Never symlink a file that an app rewrites.** Render it into a real
  local file.
- **D7: Managed keys win; unmanaged keys survive.** Render merges desired
  managed config into the existing target.
- **D8: Immutable machine files are overlay-linked after shared files.**
  Machine entries win for whole paths.
- **D9: Prefer app-native layering.** Git include, kitty include, Vim source,
  bash assembly, AWS Assume project/global rules.
- **D10: Generated artifacts and runtime state are gitignored.** Never track
  theme outputs, backups, auth, sessions, model stores, or changelogs.
- **D11: Secrets never enter the repo or render output.** No credentials,
  tokens, keys, or private profile names in tracked files.
- **D12: Machine identity is explicit and stable.** CLI, env var, or local file;
  hostname only as a fallback.
- **D13: Conservative migration and backward compatibility.** Keep wrapper
  scripts; never delete unrecognized local state; support dry-run.
- **D14: Test with a temporary `$HOME` and fixture machines.** No test writes to
  the real home directory.

These are proposals. The open questions below decide the details.

---

## 10. Open Questions (resume here)

### Carried over

- [ ] **Script structure**: one unified `homelander` with subcommands (`link`,
  `render`, `assemble`, `machine`, `doctor`) versus separate scripts behind an
  orchestrator?
- [ ] **Directory naming**: what to call the trees under `homelander/`? `_home`
  is not great. Proposed: `_home`, `_render`, `_machines/<name>/_home`,
  `_machines/<name>/_patch`. Confirm or rename.
- [ ] **Scenario 1 vs 2 distinction**: do standalone files and whole directories
  need separate handling, or does one recursive link strategy cover both?
- [ ] **Depth handling for scenario 3**: recursive walk to arbitrary depth, or a
  cap? Recursive seems right, but confirm.
- [ ] **Error/conflict handling**: keep the current `fail` and skip behavior for
  non-symlink collisions, or change it?
- [ ] **Cleanup/unlinking**: is a reverse operation needed to remove managed
  symlinks? What should it do with rendered files?

### New

- [ ] **Machine inventory**: which machines exist, and what are their stable
  profile names (`work-linux`, `home-linux`, `work-mac`, ...)?
- [ ] **Machine identity source**: CLI only, env var, local file, or hostname
  fallback? Where is the local machine file stored?
- [ ] **Machine profile layout**: `_machines/<name>/_home` plus `_patch` as
  proposed, or a manifest that lists entries and modes?
- [ ] **Render semantics**: deep merge preserving unmanaged keys as proposed?
  Arrays replace or union for specific keys (`packages`, `enabledModels`,
  `hooks`)? How do we delete a managed key?
- [ ] **Pi managed keys**: which keys are managed versus local? Is `theme` owned
  by `color-theme` only? Are `packages` shared or per-machine?
- [ ] **Claude managed keys**: are Orca hooks repo config, machine config, or
  app runtime? Should `model`/`theme` be managed at all?
- [ ] **AWS Assume global file**: track it, seed it from a machine profile, or
  leave it local forever? Are profile names sensitive? Which projects get
  policies?
- [ ] **`.my_profiles.json`**: is it machine-specific, sensitive, or shared?
  Should it move out of the repo?
- [ ] **Theme flow**: should `color-theme` stop mutating Pi settings and let the
  render apply the theme from `~/.config/env-ubuntu/color-theme`? Or keep the
  current behavior and treat `theme` as local?
- [ ] **Capture/adopt command**: do we need a command to pull intentional live
  changes back into base or machine patch? Or is `diff`/manual edit enough?
- [ ] **Generated files**: which outputs should be gitignored and regenerated?
  Confirm the theme set and any installers that write into the repo.
- [ ] **Branch migration**: which branch is canonical? How do we extract machine
  profiles without losing feature work? Which branches can be archived?
- [ ] **Secrets policy**: add a pre-commit guard for credentials, tokens, and
  private AWS profile names? Which paths are forbidden?
- [ ] **Testing**: plain bash test runner or `bats`? Which cases run in CI? Do we
  add a macOS runner?
- [ ] **Backward compatibility**: keep `homelinker.bash` and `homelander.bash`
  wrappers indefinitely, or deprecate after one migration cycle?
- [ ] **Legacy migration code**: when can `is_managed_container` and the legacy
  branch in `link_entry` be removed?
- [ ] **Platform scope**: is WSL/Windows in scope? The Orca hooks include
  Windows branches, but the repo currently targets Linux and macOS.

---

## 11. Design Goals

To be refined after the open questions, but the current goals are:

1. **One branch, many machines.** `git checkout` must not change live app
   configuration.
2. **No app writes into git-tracked files.** A runtime write never dirties the
   repo.
3. **Reproducible new-machine bootstrap.** Shared plus one machine profile is
   enough.
4. **Shared changes roll out once.** No cherry-picking to machine branches.
5. **Machine differences are visible.** One profile per machine, small and
   reviewable.
6. **Local choices survive.** Re-rendering does not reset theme, model, or other
   unmanaged keys.
7. **No secrets in git.** Credentials, tokens, and private profile names stay
   out.
8. **Testable.** Temp `$HOME`, fixture machines, dry-run, idempotent second run.
9. **Minimal dependencies.** Bash, git, `jq`; no new runtime unless justified.
10. **Conservative conflicts.** Preserve local state; report what was skipped.
11. **Backward-compatible migration.** Existing symlinks and trees can be
    migrated without data loss.
12. **Fast.** Only walk managed trees, not the whole home directory.

---

## 12. Proposed Migration Plan

### Phase 0: Inventory

- Build `docs/config-inventory.md` with one row per managed path: current
  deployment, variation class, proposed mode.
- Add a `homelander doctor` or `--dry-run` view that prints what would be
  linked, rendered, generated, or ignored.
- Verify the classification table in section 7 against every tracked path under
  `homelander/_home`.

### Phase 1: Machine identity and layout

- Add `--machine` and `ENV_UBUNTU_MACHINE`.
- Add `_machines/<name>/_home` and `_machines/<name>/_patch` skeletons for the
  current machines.
- Fail clearly when the profile is missing; do not guess.
- Write the selected machine to `~/.config/env-ubuntu/machine` on success.

### Phase 2: Git config (low risk, immediate win)

- Add `[include] path = ~/.gitconfig.local` to the shared `.gitconfig`.
- Move `core.excludesfile` and `commit.template` into `.gitconfig.local`.
- Seed `.gitconfig.local` only if missing; never overwrite.
- Test on Linux and macOS.

### Phase 3: Generated theme files

- Replace the live symlinks for `color-theme`, `kitty-theme.conf`, and
  `git-theme.gitconfig` with real local files.
- Remove those files from tracking; add them to `.gitignore`.
- Keep `themes/kitty/*` and `themes/git/*` as source.
- Adjust `color-theme` if needed so a missing local file is handled.
- Verify that `color-theme default` and `color-theme remarkable` leave
  `git status` clean.

### Phase 4: Pi settings

- Create `_render/.pi/agent/settings.json` from shared keys.
- Create machine patches for provider/model/enabledModels/npmCommand/packages.
- Stop symlinking `~/.pi/agent/settings.json`; render it.
- Ensure `lastChangelogVersion` and `extensionChangelogVersions` are never in
  base or patch.
- Decide whether `theme` is local-only or applied from the local theme file.
- Verify Pi starts, `color-theme` works, and a second render is idempotent.

### Phase 5: Claude settings

- Create `_render/.claude/settings.json` from shared keys.
- Decide whether Orca hooks are machine patch or app-owned.
- Remove `settings.json.bak` from tracking; gitignore it.
- Materialize `~/.claude` so managed files can coexist with credentials,
  sessions, and history.
- Verify Claude starts and Orca hooks still work.

### Phase 6: AWS Assume and other machine-local config

- Decide whether `~/.pi/agent/aws-assume.json` is tracked, seeded, or local.
- Keep project policies in project repos.
- Verify `env-ubuntu` remains without a policy unless explicitly wanted.
- Classify `.my_profiles.json` and move it out of the repo if sensitive.

### Phase 7: Branch consolidation

- Extract the remaining machine differences from `main` and each machine branch
  into machine profiles.
- Merge genuine feature drift (starship modules, Vim theme sync, kitty tab
  title, installers) into `main` as shared.
- Archive machine branches after verification. Keep feature branches separate.

### Phase 8: Cleanup

- Remove legacy migration code once every machine has run the new bootstrap.
- Update `README.md`, `CLAUDE.md`, and `AGENTS.md` with the new model.
- Add tests and CI.
- Remove the manual `materialized_directories` list once the orchestrator can
  compute materialization from the shared + machine path union.

---

## 13. Testing Strategy

Use a temporary `$HOME` for every test. The test harness must fail if it detects
the real home directory.

Suggested cases:

1. Link a shared file into a temp home.
2. Link a shared directory as one symlink.
3. Materialize a directory and link its children.
4. Machine overlay replaces a shared whole file.
5. Machine overlay adds a file inside a materialized directory.
6. Render base + patch into a new target.
7. Render into an existing target preserves unmanaged keys.
8. Render updates managed keys.
9. Render handles arrays according to the chosen policy.
10. Render is idempotent.
11. Render replaces a symlink into the repo with a regular file, after
    verification.
12. Conflict with a real file preserves the file and reports it.
13. Missing machine profile fails with a helpful message and a profile list.
14. Dry-run makes no changes.
15. No secret path is ever copied or tracked.

Test fixtures:

```text
test/fixtures/
  base/.pi/agent/settings.json
  machines/work-linux/_patch/.pi/agent/settings.json
  machines/home-linux/_patch/.pi/agent/settings.json
  home/.pi/agent/settings.json
```

Use `jq -S` for stable JSON comparisons. Run `shellcheck` on every script. A
plain bash runner is enough; `bats` is optional.

---

## 14. Agreed Plan / Implementation

To be written once the open questions in section 10 are resolved.

The likely first implementation slice is small and testable:

1. Add `homelander render` with JSON fixture tests.
2. Add machine identity and the `_machines` layout.
3. Migrate `.gitconfig` to `include`.
4. Migrate Pi settings.
5. Migrate Claude settings.
6. Move generated theme files out of git.
7. Consolidate branches.

Do not start with a full rewrite. The current link behavior is working for most
files. Add the render path alongside it, prove it with tests, then migrate one
file at a time.
