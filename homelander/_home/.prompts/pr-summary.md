## Goal

Create a PR summary from the provided diff/changes following the **Output Template** section below.

**What to analyze:**
- Functional changes to code, configuration, and infrastructure
- Changes in development patterns or workflows
- New features, bug fixes, refactoring, and architectural updates

**What to ignore:**
- Comment changes
- Whitespace and formatting
- Pure code style adjustments

**Formatting conventions:**
- Wrap tool/command names in backticks: `gh`, `fzf`, `docker`, `npm`, etc.
- Wrap file/directory names in backticks: `.env`, `package.json`, `src/`, etc.
- Wrap code identifiers in backticks: function names, variable names, config keys, etc.

**See the "Output Template" section below for exact structure and formatting requirements.**

---

# Output Template

The output must follow this exact structure:

## Section 1: PR Title (REQUIRED)

````markdown
```
type(scope): brief description
```
````

**Rules:**
- Use conventional commit format: `type(scope): description`
- Types: feat, fix, refactor, docs, chore, test, ci, perf
- Scope: module/area affected (e.g., auth, api, infra, build)
- Description: lowercase, imperative mood ("add" not "adds")
- Always wrapped in triple backticks (code block)
- No "PR Title:" label or other text outside the code block

## Section 2: Overview (REQUIRED)

```markdown
## Overview

Brief paragraph explaining what this means to the user/developer, focusing on benefits and outcomes rather than technical implementation details.
```

**Rules:**
- 1-3 sentences maximum
- Answer "why does this matter?" not "what files changed?"
- Focus on user/developer impact and benefits
- Written in plain language, avoid excessive technical jargon

## Section 3: Details (REQUIRED)

```markdown
## Details

> [!NOTE]
> - First major change description
> - Second major change description
> - Third major change description
```

**Rules:**
- Must always include the Details heading and NOTE block
- Each bullet is a single line describing one major change
- Focus on WHAT changed, not HOW it was implemented
- Group related changes into single bullets when logical
- Order by importance/impact (most significant first)

## Section 4: Warnings (CONDITIONAL)

```markdown
> [!WARNING]
> - Issue with code marked XXX: description
> - Another XXX: marked area that changed
```

**Rules:**
- Only include if changes affect areas marked with `XXX:` comments
- Omit entire section if no XXX-related changes exist
- If included, appears under the Details heading after NOTE block

## Section 5: Infrastructure Impact (CONDITIONAL)

```markdown
> [!CAUTION]
> - Resources being created/updated/destroyed with impact explanation
> - Grouped infrastructure changes
```

**Rules:**
- Only include for infrastructure/resource changes with actual impact
- Group related changes, don't list every resource individually
- For `moved` blocks: only include if BOTH moved AND modified/removed
- Omit entire section if no infrastructure impact
- If included, appears under the Details heading after NOTE and WARNING blocks

------

# IaC Change Counting Rules

**Use these rules when summarizing changes. Do NOT count the following as errors or changes:**

## Refactoring (0 changes):

**State management blocks (v1.5+):**

- `moved {}` - resource relocated with identical config
- `import {}` - existing infrastructure brought under management
- `removed {}` (v1.7+) - resource removed from state only

**Validation (no infrastructure impact):**

- `check {}` - validation rules
- `precondition {}` / `postcondition {}` - lifecycle validation

## Intentional deletions (0 changes):

Pure deletions with `-block_type "` but no `+block_type "`:

- Module removals (`-module "`)
- Data source removals (`-data "`)
- Output removals (`-output "`)
- Variable removals (`-variable "`)

## Metadata only (0 changes):

- Comments (`#`, `//`)
- Whitespace/formatting
- `terraform {}` version constraints

## Quick verification:

1. In git diff: look for special blocks listed above
2. For pure deletions: `-` line without matching `+` line
3. For refactoring: old/new configs functionally identical
4. In terraform plan: "refreshing" or "reading" actions = 0 changes

## Only count as changes/errors:

- Config modifications (not just moves)
- `moved {}` + config changes together
- `import {}` with mismatched config
- Resource deleted without `removed {}` block
- Module removed but resources still referenced
- Plan shows actual infrastructure changes (create/update/destroy)
