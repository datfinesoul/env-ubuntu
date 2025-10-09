## Goal

Create a PR summary from the input I've provided

- Output should be the output in markdown form only
- The entire summary should be wrapped in a `> [!NOTE]` quote.
- Each major change should be a single markdown bulleted line
  - Correct: "Sample change that accomplishes a task"
  - Incorrect: "**Sample Change** - This sample change accomplishes a task"
- Do point out changes in development patterns
- Any changes related to areas of the code commented with `XXX:` should be added to a separate `> [!WARNING]` block.
- Put infrastructure changes (resources being updated/destroyed) from the terraform plan in a `> [!CAUTION]` block with explanation of impact.
  - For `moved` blocks: only include if BOTH moved AND modified (~) or removed (-).
  - Group related changes, don't list every resource separately.
- Omit any callout block that would be empty.
- All callout blocks should contain only bulleted line items (use `-` for bullets), no ##, ### or #### type headings.

**IMPORTANT**: Do NOT include things like comment changes, whitespace, or formatting.

At the end of the document provide a good PR title using conventional commit messaging:

- Format: `type(scope): description`
- Examples: `feat(auth): add SSO integration`, `fix(api): resolve timeout issues`, `refactor(iac): reorganize terraform modules`

Following the PR Title, output a sentence or paragraph with summary focusing purely on what this means to the user, instead of focusing on technical details.

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
