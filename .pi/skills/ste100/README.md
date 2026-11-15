# STE100

Project-local adaptation of [danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill), upstream version `0.4.0`, pinned to commit [`3944283c183eea13fe5bd902b572da3b4de8bf44`](https://github.com/danyuchn/asd-ste100-skill/tree/3944283c183eea13fe5bd902b572da3b4de8bf44).

Adopted from the STE100 skill in `datfinesoul/acp/pi-infra` (previously `datfinesoul/acp-pi-extensions`, commit `e5a04d30109f641287af19f28d3b851c897dcb22`). This copy keeps only the generic writing guidance. It preserves verbatim user records.

## Try it

Run `/reload` in Pi after changing the skill. Agents read and apply it when writing or updating documentation or PR titles/descriptions. These tasks use STE-flavored mode.

For other text, invoke the skill explicitly:

```text
/skill:ste100 Rewrite this tool description. Preserve every condition. Show the before/after comparison: <text>
```

The skill returns rewritten text by default. Ask for a before/after comparison to see the rules behind each change. Automatic use is limited to documentation and PR text. It excludes ordinary replies, code, runtime messages, and verbatim user records.

The optional linter requires Python 3 and uses only the standard library. Run it from the repository root:

```bash
python3 .pi/skills/ste100/scripts/ste-lint.py --selftest
python3 .pi/skills/ste100/scripts/ste-lint.py --json path/to/document.md
```

The linter reports possible structural issues. It does not verify meaning, requirement strength, or full ASD-STE100 compliance. Review each finding. No mandatory STE lint gate is added to CI.

## Included files and local changes

- `SKILL.md`: upstream instructions, renamed to `ste100`, with license, compatibility, and source metadata, scoped automatic selection, and a generic project scope section. The ACP-specific section was removed.
- `scripts/ste-lint.py`: unchanged upstream linter and built-in tests.
- `references/writing-rules.md`: unchanged upstream summary and sources.
- `examples/`: unchanged upstream examples and intentionally invalid linter fixture.
- `LICENSE`: unchanged upstream MIT license, copyright 2026 Dustin Yuchen Teng.

This is a vendored snapshot, not a submodule or global installation. Updates are manual. Review upstream changes and record the new revision when updating the snapshot. The official ASD dictionary is not included.
