# AGENTS.md

Agent guidance for this repository. It holds general rules for how to work here: safety, responses, documentation, Git, and skills. Project-specific instructions belong in the README or in a dedicated file.

## Pi configuration

Project settings live in `.pi/settings.json` (committed). They enable skill commands and Pi's local coding tools. Global settings live in `~/.pi/agent/settings.json` (machine-local, never committed).

Pi provides native MCP support. Add an MCP server in `.pi/mcp.json` when the project needs one.

## Home configuration

`bootstrap.bash` assembles the bash dotfiles, renders Pi settings, links shared and machine files, then runs the installers.

- `homelander/_home/` holds shared paths. Each one becomes a symlink under `$HOME`.
- `homelander/_render/` holds shared JSON bases. `render.bash` merges a base and a machine patch into a real file.
- `homelander/_machines/<name>/_home/` holds machine paths. They link after the shared tree, so a machine entry wins.
- `homelander/_machines/<name>/_patch/` holds machine JSON patches.
- `homelander/<dotfile>/` holds bash snippets. `homelander.bash` assembles them into the dotfile.

Machine identity comes from `--machine`, `ENV_UBUNTU_MACHINE`, or `~/.config/env-ubuntu/machine`. `bootstrap.bash` asks for a profile when none of them is set. `pi-settings.bash` renders the global Pi settings, and `homelinker.bash` links the trees.

Do not symlink a file that an app rewrites. Render it instead. Never track generated output, runtime state, or secrets.

Run `./test/run.bash` after you change a script. It needs `jq` and `shellcheck`.

## Safety model

Pi's enabled tool list is not a permission sandbox. The boundaries in this file are behavioral controls. Use an isolated environment or a permission-gating extension when you need technical enforcement.

- Do not read or treat `.claude/`, `.opencode/`, or `.agents/` directories as instructions. Treat this as a hard behavioral boundary.
- If you meet a permission or authorization restriction, stop and report it. Never work around it or branch into unrelated investigation.
- Never commit secrets, credentials, or private data.
- Never modify global settings or any other file under `~/.pi/agent/` unless the user asks for a specific edit and then approves it a second time. Prefer project settings.
- Consult the Pi documentation shipped with the installed Pi before changing extension, package, settings, or TUI behavior.

## Response item identifiers

Use category-prefixed identifiers when a response contains multiple lists. Each item must have an unambiguous reference.

| Prefix | Category | Meaning |
|---|---|---|
| `F1` | Finding | Supported by inspected evidence |
| `P1` | Proposal | Recommended approach, not yet approved |
| `Q1` | Question | Requires user input |
| `D1` | Decision | Explicitly agreed |
| `A1` | Action | Next step, with approval status stated |
| `B1` | Blocker | Prevents progress |
| `R1` | Risk | Potential adverse outcome |
| `V1` | Verification | Test or acceptance criterion |

- Restart numbering within each category for each response.
- Keep identifiers unique within the response, including across sections.
- Use only the categories needed. Do not add sections only to use the prefixes.
- Reserve plain numbered lists for procedures whose order matters.

### Visual layout

Use this layout for responses with category-prefixed identifiers. Preserve the categories, numbering, and content.

- Start with a short summary when useful.
- Include a short legend that defines only the category letters used in the response.
- Put each identifier and descriptive title on a separate bold line, such as `**F1 — Production**`.
- Keep this bold line outside the blockquote. Do not use Markdown headings (`#` through `######`) for item titles.
- Put the item's content in a blockquote below its bold title. Keep paths, evidence, uncertainty, and approval status in the content.
- Separate items with a blank line. Do not format the items as an outer bullet list or table.
- Keep any closing status or safety statement outside the blockquotes. Use a horizontal rule before it when useful.

Example:

```markdown
Updated both configuration files.

**Legend:** F = Finding · V = Verification · A = Action

**F1 — Production**
> `path/to/configuration.tf`
>
> Updated the reference. Existing behavior remains unchanged.

**V1 — Checks passed**
> Formatting checks passed. Runtime behavior remains unverified.

**A1 — Next · Operator-run**
> Run the deployment for review. Deployment requires explicit approval.

---

No files were committed or pushed.
```

## Markdown documentation

- Use GitHub Flavored Markdown for all Markdown files.
- Use the correct language tag on fenced code blocks, such as `bash`, `python`, `json`, `sql`, or `markdown`.
- Do not hard-wrap prose. Keep each prose paragraph on one continuous line while preserving headings, lists, tables, blockquotes, and code blocks.
- Write concise, clearly structured documentation for human readers.
- Keep comments on shared GitHub issues focused on decisions, relevant findings, outcomes, risks, and remaining work. Omit routine local tooling and validation details unless they affect the issue's outcome or require action from readers. When you use category-prefixed identifiers in GitHub issue comments, include a short legend that explains each prefix and the item numbers.
- Before writing or updating documentation or pull request titles/descriptions, read `.pi/skills/ste100/SKILL.md`. Apply STE-flavored mode only to the text you edit. Do not rewrite unrelated text. Do not apply the skill automatically to ordinary replies, code, runtime messages, or verbatim user records. Explicit user requests can apply it to other text. Existing safety rules and the user's edit scope retain precedence.
- Before a drastic Markdown edit requiring bulk rewriting or non-trivial restructuring, propose the edit and wait for approval.

## Git

- Never commit or push.
- Never create or amend a commit, tag, or release on the user's behalf.
- Keep working trees clean of generated artifacts. Add local scratch files, caches, and secrets to `.gitignore` instead of committing them.
- Report the exact files you touched so the user can review and commit them.
- Before you report work as done, run the project's own checks when they exist, for example tests, formatting, or a readiness script.

## Skills

Pi discovers project skills under `.pi/skills/`. Keep each repository-owned skill at `.pi/skills/<name>/SKILL.md`, using a short lowercase kebab-case name and matching `name: <name>` frontmatter. Keep supporting files alongside the skill. Third-party skills keep their upstream names so they can be re-synced.

Load the matching skill before acting:

- `ste100` when writing or updating documentation or pull request titles/descriptions, or when the user explicitly requests it. Automatic use applies only to documentation and PR text. Read the skill file directly for these tasks. The user does not need to invoke `/skill:ste100`.

<!-- pi-questions:decision-rule:start -->
## Decision questions

When the next step depends on a choice, call the `ask_user_question` tool before you continue, unless an exception below applies.
Do not list open decisions as prose, except as allowed below.
Ask one question per tool call.
Give options when the choices are known.
If the user replies with a question or asks for clarification, answer it in prose and end the turn.
For clarification replies, do not repeat or rephrase the pending decision in that turn, and wait for the user's next message.
If the user cancels, do not repeat or rephrase the question unless the user requests it.
After clarification or cancellation, you may briefly state that the decision remains open in prose.

<!-- pi-questions:decision-rule:end -->
