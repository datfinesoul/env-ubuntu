# Homelinker Redesign — Discussion & Plan

## Current State

### homelinker.bash (current behavior)
- Sources `_core.bash` for logging and common setup
- Walks `homelander/_home/` at depth 1
- **Files**: symlinks `$HOME/<name>` -> `homelander/_home/<name>`
- **Directories**: creates `$HOME/<dir>/`, then symlinks each file inside (depth 1 only)
- Skips existing non-symlink targets (logs `fail` and continues)
- Max depth: 2 levels total (no recursive subdirectory handling)

### homelander.bash (current behavior)
- Takes a `<dotfile>` arg (e.g., `.bashrc`) and optional `[target]` (defaults to `$HOME/<dotfile>`)
- Looks in `homelander/<dotfile>/` for `*.bash` snippet files
- Strips `#[+]:label:` / `#[-]:label:` delimited sections from the target file (idempotent cleanup)
- Then re-appends each `*.bash` file's contents (comments/blanks stripped) wrapped in those delimiters
- Assembles a dotfile by concatenating snippets from a plugin directory

### bootstrap.bash invocations (current)
```bash
homelander.bash .bash_profile   # assembles $HOME/.bash_profile from snippets
homelander.bash .bashrc         # assembles $HOME/.bashrc from snippets
homelinker.bash                 # symlinks homelander/_home/ contents into $HOME
```

### Key facts from history
- Target has always been `$HOME` — never changed across the entire git history
- The two scripts are invoked separately with no shared orchestration

## Problem Space (4 scenarios)

1. **Standalone files** (e.g., `.gitconfig`) — symlink whole file, fully version controlled
2. **Whole directories** (e.g., `.vim/`) — symlink entire dir, fully version controlled
3. **Mixed directories** (e.g., `~/.config/opencode/`) — some files symlinked/versioned, rest ignored. Currently underserved — homelinker only goes 2 levels deep
4. **Assembled files** (e.g., `.bashrc`) — compose a file from labeled snippets

## Decisions Made

### D1: Scenario 4 — keep label/snippet approach
- `#+:label:` / `#-:label:` delimiters work well, no changes needed

### D2: Repo structure — two separate trees (Option D)
- Separate dirs under `homelander/` for different linking strategies
- Most explicit, no magic files, directory placement declares intent
- Rejected alternatives:
  - A (always file-level) — misses new files in fully-versioned dirs
  - B (.gitignore-based) — wrong layer, conflates git tracking with deployment
  - C (sentinel marker files) — hidden magic in dotfiles

### D3: Target mapping — pass source/target as CLI args (Option 4)
- Script signature: `./script <strategy> <source_dir> <target_dir>`
- No config files, no dotfiles, no naming conventions
- Orchestrator (bootstrap.bash) declares the mappings explicitly
- **Deciding factor: testability** — trivially testable with temp dirs as target; `.target` dotfiles would require setup/mocking
- Trade-off: adding a new deployment requires editing orchestrator (low frequency, acceptable)
- Rejected alternatives:
  - Opt 1 (central config file) — extra file to maintain
  - Opt 2 (dir name = target path) — breaks down for $HOME
  - Opt 3 (.target dotfile per dir) — harder to test, requires filtering during symlinking

## Open Questions (resume here)

- [ ] **Script structure**: one unified script with subcommands (e.g., `homelander symlink`, `homelander sparse`, `homelander assemble`) vs separate scripts behind an orchestrator?
- [ ] **Directory naming**: what to call the trees under `homelander/` — current `_home` is not great; needs names for the whole-dir tree and the file-level tree
- [ ] **Scenario 1 vs 2 distinction**: do standalone files and whole directories need separate handling, or does one recursive symlink strategy cover both?
- [ ] **Depth handling for scenario 3**: recursive walk to arbitrary depth, or cap it? (Recursive seems right but worth confirming)
- [ ] **Error/conflict handling**: current approach logs `fail` and skips non-symlink collisions — keep this, or change behavior?
- [ ] **Cleanup/unlinking**: any need for a reverse operation that removes managed symlinks?

## Design Goals
(to be refined after open questions are resolved)

## Agreed Plan / Implementation
(to be written once design is settled)
