# Git signing migration: GPG to native SSH

## Goal and scope

Use native SSH signatures for Git commits and signed tags on macOS and Linux, including an interactive terminal with no graphical desktop. Keep GPG working until both platforms pass the pilot.

This file is a plan, not an installer. Commands below are proposed manual steps. Do not execute every phase automatically.

## Agreed requirements

- Dedicated Ed25519 signing key per machine.
- Private keys encrypted with a strong passphrase.
- Unlock from a terminal using standard OpenSSH tools.
- One-hour maximum lifetime in `ssh-agent`, measured from loading, not from last use.
- Public keys registered separately as GitHub **Signing keys**.
- No dependency on Bitwarden Desktop, 1Password, a graphical session, or macOS Keychain.
- Keep private keys and passphrases outside this repository.
- Do not revoke GPG keys or rewrite existing commits as part of migration.

## Assumptions and boundaries

- Headless means an interactive terminal, possibly over SSH. Unattended CI signing needs a separate design.
- Each Linux machine or persistent development environment gets its own signing key; do not copy the Mac's private key into it.
- Tests use a dedicated agent without forwarding. Agent forwarding is not the baseline.
- Signing works with HTTPS or SSH Git remotes. Do not change remote authentication as a side effect.
- A valid signature proves control of a signing key, not review or safety of the signed code.
- Processes with access to an unlocked agent can request signatures during its lifetime.
- GitHub verification and local verification are separate trust configurations.
- Project-specific policies may still require GPG or DCO sign-off.

## Initial findings

- Observed on the current Mac: Git 2.55.0 and OpenSSH 10.5p1.
- Recheck versions on each test host. Use Git >= 2.34 and OpenSSH >= 8.8 as the baseline documented by Bitwarden for SSH signing.
- `homelander/_home/.gitconfig` selects GPG key `4A4F755890424725` and enables `commit.gpgsign`.
- `~/.gitconfig.local` is included before the hard-coded signing key. A signing key placed only in that local file is currently overridden later.
- The shared config also contains a Mac-specific commit-template path. Isolated tests must disable that template locally so a Linux failure does not get confused with a signing failure.
- `installers/bw.manual.bash` installs the CLI, not a headless signing agent.
- `scripts/get-profile-ssh-keys.bash` exports key attachments into `~/.ssh`; it is not needed for this design and will not be changed during the pilot.
- An unrelated change exists in `homelander/_home/.pi/agent/settings.json`. Leave it untouched.

## Status

- [x] Save migration plan.
- [ ] Phase 0: read-only preflight on both hosts.
- [ ] Phase 1: isolated macOS signing test.
- [ ] Phase 2: isolated headless Linux signing test.
- [ ] Phase 3: GitHub verification test.
- [ ] Phase 4: daily agent workflow and recovery decisions.
- [ ] Phase 5: machine-specific default configuration.
- [ ] Phase 6: acceptance and transition closeout.

Record host versions, results, and decisions here as we proceed. Never record private keys, passphrases, vault sessions, or tokens.

## Phase 0 — Read-only preflight

### Steps

1. Choose the Linux test environment: an existing trusted headless host, a persistent VM, or a disposable local container for a preliminary smoke test.
2. Record `git --version` and `ssh -V` on each host.
3. Inspect only relevant effective configuration and its origins:

   ```bash
   git config --show-origin --get-regexp \
     '^(gpg\..*|commit\.gpgsign|tag\.gpgsign|user\.signingkey|user\.email|commit\.template|core\.hooksPath)$'
   ```

4. Establish whether the terminal already uses a local agent or a forwarded agent. Do not replace the current shell's agent or enumerate unrelated private keys.
5. Confirm the intended commit email belongs to the GitHub account. The existing noreply address is the starting candidate.
6. Record the current effective GPG signing settings for rollback. Do not copy entire configuration files into the plan.
7. Check for additional `CLAUDE.md` instructions before future code or shell configuration changes.

### Gate

Both hosts and their interactive terminals are identified. Configuration conflicts are understood. No key generation or configuration changes yet.

## Phase 1 — Isolated macOS signing test

### Safety rules

- User runs passphrase prompts in their own terminal. The assistant must not receive the passphrase.
- Use a new test repository and a dedicated test agent. Do not modify global Git config.
- Do not stage files from this working repository. An empty test commit needs no staging.
- Do not overwrite an existing key or replace an existing allowed-signers file.

### Steps

1. With explicit approval, generate a dedicated passphrase-encrypted signing key outside this repository:

   ```bash
   ssh-keygen -t ed25519 \
     -f "$HOME/.ssh/git_signing_ed25519" \
     -C "git-signing:<machine-label>"
   ```

   Check that the destination does not exist first. Create `~/.ssh` with private directory permissions if needed. Enter a strong passphrase interactively; never use `-N ''` or a passphrase in command arguments.

2. Start the pilot inside a subshell with its own `ssh-agent`. Register cleanup to terminate only that agent when the subshell exits. This must not change the parent shell's `SSH_AUTH_SOCK` or kill an existing agent.
3. Load the key interactively:

   ```bash
   ssh-add -t 1h "$HOME/.ssh/git_signing_ed25519"
   ```

4. Create an isolated scratch repository. Set the following **repository-local** values:

   ```ini
   [gpg]
       format = ssh
   [gpg "ssh"]
       program = ssh-keygen
       allowedSignersFile = <absolute-path-to-test-allowed-signers>
   [user]
       name = <your-name>
       email = <verified-github-email>
       signingkey = <absolute-path-to-signing-key.pub>
   [commit]
       gpgsign = true
       template =
   ```

   Use expanded absolute paths when writing settings. Isolate hooks in an empty test-only hooks directory if inherited hooks would affect the test. Review any inherited SSH revocation or verification settings rather than silently changing them globally.

5. Create a test-only allowed-signers file containing:

   ```text
   <verified-github-email> namespaces="git" ssh-ed25519 <public-key-base64>
   ```

   This file contains public data only. Do not overwrite a real trust file.

6. After explicit approval to create objects in the scratch repository, make an empty signed commit and a signed annotated tag:

   ```bash
   git commit --allow-empty -m "Test SSH commit signing"
   git verify-commit HEAD
   git tag -s ssh-signing-test -m "Test SSH tag signing"
   git verify-tag ssh-signing-test
   ```

7. Test expiry without waiting an hour: remove the key from the dedicated pilot agent, reload it with `ssh-add -t 60s <private-key-path>`, and wait beyond that lifetime.
8. Confirm the dedicated agent no longer lists the key. Attempting another signed empty commit must fail without creating a commit. Existing signatures must still verify because verification requires only public material.
9. Reload the key with `-t 1h`; confirm signing works again.
10. Exit the subshell and verify the dedicated pilot agent has stopped. Confirm original global signing settings are unchanged.

### Gate

Passphrase entry, commit signing, tag signing, local verification, expiry, failure after expiry, and re-unlock all work without a password-manager GUI.

## Phase 2 — Isolated headless Linux signing test

Repeat Phase 1 on Linux with a separate key and scratch repository.

Additional checks:

- Run from a terminal with no graphical session or askpass dependency.
- Use a host-local agent, not an agent forwarded from the Mac.
- Confirm passphrase entry works through the terminal.
- Confirm expired-key failure does not open a graphical prompt or hang waiting for one.
- Check permissions on the private key and its directory.
- Confirm a terminal disconnect/reconnect does not silently create an indefinitely unlocked agent. Persistent agent behavior is a Phase 4 design decision.

A container can prove CLI compatibility, but does not replace testing the actual Linux login/session lifecycle. Do not mount the Mac's private key or host agent socket into a preliminary container test. If using a disposable key there, do not treat it as the final persistent Linux machine identity.

### Gate

All functional tests pass on a real headless workflow, with no desktop process required.

## Phase 3 — GitHub verification test

### Steps

1. User registers each approved machine's public key in GitHub Settings > SSH and GPG keys > New SSH key, selecting **Signing key**.
2. Check the displayed fingerprints against the local public keys.
3. Choose an existing suitable test repository or explicitly approve creation of a scratch GitHub repository. Do not push to an open-source project's branch for testing.
4. Approve the exact remote and branch before pushing the signed test commit. Publish the test tag only if tag testing on GitHub is desired and approved.
5. Verify the commit displays **Verified** and that its key and account attribution are correct.
6. Repeat for the other machine's key. Both should verify under the same account.
7. Confirm no change to remote authentication was necessary.

### Gate

One signed commit from each machine verifies locally and on GitHub.

## Phase 4 — Daily agent workflow and recovery

Decide the workflow before changing shell startup files.

### Proposed default

- Reuse the platform's suitable local agent when one exists.
- Provide an explicit terminal command to unlock only the dedicated signing key for one hour.
- Do not start a new agent in every shell.
- Do not auto-load the key without an explicit lifetime.
- Do not store the passphrase in Keychain, shell files, environment variables, or a password-manager session for automatic re-unlock.
- Avoid signing-agent forwarding by default.
- Preserve unrelated SSH authentication keys and existing agent behavior.
- A key may need explicit reloading in each separate agent; a key file being present does not mean that agent has it loaded.

### Decisions to record

1. Agent lifecycle on macOS and Linux, including SSH reconnects and multiple terminals.
2. Whether an optional unlock helper is useful. If implemented, it must work in terminal-only sessions and refuse unsafe assumptions about forwarded agents.
3. Backup policy: either encrypted recovery material or deliberately replaceable per-machine keys. Do not copy private keys into the repository.
4. How to remove a lost/compromised machine's signing key from GitHub and from local trust lists.
5. Which projects, if any, must continue using GPG through repository-local configuration or conditional includes.
6. Whether to enable `tag.gpgsign` automatically. Explicit signed tags are tested, but automatic tag signing is not assumed.

### Gate

The normal workflow enforces a one-hour lifetime without disrupting existing SSH authentication. Recovery and replacement expectations are clear.

## Phase 5 — Machine-specific default configuration

Only proceed after both platforms and GitHub verification pass.

### Proposed repository changes

1. Review the full shared `.gitconfig` before choosing the minimal edit.
2. Move the local override include after shared defaults, while preserving the intended final theme override. Review non-signing consequences of this precedence change.
3. Keep the existing shared GPG default during the transition. On migrated hosts, place `gpg.format = ssh` and the machine's public-key path in the later-loaded, machine-local configuration.
4. Retain `commit.gpgsign = true`; the setting name applies to SSH signatures too.
5. Configure a persistent allowed-signers file on each host. Preserve existing entries and add both approved machine public keys so either machine can verify the other's signatures locally.
6. If local trust entries are version-controlled, include public keys only and review additions as security-sensitive trust changes.
7. Add concise setup and unlock instructions. Add a shell helper only if Phase 4 establishes a need.
8. Ensure future bootstrap runs do not overwrite or bypass machine-local key selection.
9. After the transition, separately decide whether to remove the hard-coded shared GPG key. Do not strand hosts that have not migrated.

### Validation

- Review effective signing settings with `--show-origin` on each host and in representative repositories.
- Repeat signed commit/tag and expiry tests after configuration changes.
- Verify local checks work for signatures from both machine keys.
- Test real editor/terminal workflows in scratch repositories before normal use.
- Confirm GPG-specific repositories still use GPG.
- Confirm unrelated configuration and pending changes remain untouched.

## Phase 6 — Acceptance and closeout

- [ ] macOS terminal signing and verification pass.
- [ ] Headless Linux signing and verification pass.
- [ ] Both public keys produce GitHub Verified commits.
- [ ] One-hour unlock policy is explicit and documented.
- [ ] Short-lived expiry test fails closed and re-unlock restores signing.
- [ ] Existing commits and tags are unchanged.
- [ ] GPG remains usable for exceptions and rollback.
- [ ] Backup/replacement policy is recorded.
- [ ] Agent lifecycle does not leak extra agents or alter unrelated authentication.
- [ ] No private material enters Git, logs, or the plan.

Do not stage or commit repository changes without explicit approval.

## Rollback

- During the pilot: exit the dedicated agent subshell and leave the scratch repository unused. Global GPG settings remain untouched.
- During rollout: remove only the SSH overrides introduced for this migration and restore the recorded signing settings. Do not blindly unset pre-existing values.
- Restore include precedence if its change causes unrelated regressions.
- Keep the original GPG key available. Test rollback in a scratch repository before relying on it.
- Remove test-only GitHub keys or test repositories only with explicit approval. Do not delete final machine keys accidentally.
- Never rewrite history to replace old signatures.

## Verification references

- GitHub supported signatures, multiple keys, and persistent verification: https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification
- Git SSH signing-key configuration: https://github.com/git/git/blob/master/Documentation/config/user.adoc
- Git SSH verification configuration: https://github.com/git/git/blob/master/Documentation/config/gpg.adoc
- OpenSSH terminal passphrase entry and key lifetimes: https://man.openbsd.org/ssh-add
- OpenSSH agent lifecycle: https://man.openbsd.org/ssh-agent
- Bitwarden desktop-agent requirements: https://bitwarden.com/help/ssh-agent/

## Execution log

### Planning

- Plan created. No key generation, signing configuration changes, test commits, staging, or remote operations performed.
### Phase 0 — macOS preflight

- User selected an existing Linux host for the headless test. No remote connection or remote execution has been authorized or performed.
- Current host: Darwin; Git 2.55.0; OpenSSH 10.5p1.
- Effective signing settings originate in `~/.gitconfig`: GPG key `4A4F755890424725`, automatic commit signing enabled, existing GitHub noreply email, and a Mac-specific commit template.
- The configuration query returned no explicit `gpg.*`, automatic tag-signing, or hooks-path settings.
- `SSH_AUTH_SOCK` points to a macOS launchd socket. No `SSH_CONNECTION` or `DISPLAY` is present. The pilot will still use a separate agent rather than altering the existing socket.
- Proposed private and public key paths `~/.ssh/git_signing_ed25519{,.pub}` do not exist on this Mac.
- No agent keys were enumerated. No signing or key generation occurred.
- Next action: user runs the read-only preflight on the chosen Linux host and supplies the results. Confirm the GitHub email separately before registering keys.
