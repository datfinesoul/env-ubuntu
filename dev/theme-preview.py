#!/usr/bin/env python3
"""Print every env-ubuntu theme surface in the terminal.

Reads the same tracked files that `color_theme <name>` applies, so what you see
here is what Kitty, btop, Vim, Git delta, bat, jq, and Pi will render. Use it to
debug a palette change before or after switching themes.

Run it from any directory:

    python3 dev/theme-preview.py              # active theme
    python3 dev/theme-preview.py remarkable   # one theme
    python3 dev/theme-preview.py --all        # every theme

Environment:
    NO_COLOR=1     print hex values only, without escape sequences
    ENV_UBUNTU_ROOT  repo root override, as used by functions/color-theme.bash
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(
    os.environ.get("ENV_UBUNTU_ROOT") or Path(__file__).resolve().parent.parent
).resolve()
HOME = Path(os.environ.get("HOME", "~")).expanduser()

THEMES: dict[str, dict[str, str | None]] = {
    "default": {
        "mode": "dark",
        "palette": "homelander/_home/.config/base16-shell/base16-default.dark.sh",
        "kitty": "themes/kitty/default.conf",
        "git": "themes/git/default.gitconfig",
        "vim": "homelander/_home/.vim/pack/datfinesoul/start/base16-vim/colors/base16-default-dark.vim",
        "pi": None,
        "pi_name": "dark",
        "bat": "1337",
        "btop": "themes/btop/default.theme",
    },
    "remarkable": {
        "mode": "light",
        "palette": "homelander/_home/.config/base16-shell/base16-remarkable.light.sh",
        "kitty": "themes/kitty/remarkable.conf",
        "git": "themes/git/remarkable.gitconfig",
        "vim": "homelander/_home/.vim/colors/base16-remarkable-light.vim",
        "pi": "homelander/_home/.pi/agent/themes/remarkable.json",
        "pi_name": "remarkable",
        "bat": "ansi",
        "btop": "themes/btop/remarkable.theme",
    },
}

SGR_ATTRS = {
    "bold": 1,
    "dim": 2,
    "italic": 3,
    "underline": 4,
    "ul": 4,
    "reverse": 7,
    "hidden": 8,
    "strikethrough": 9,
}

HEX_RE = re.compile(r"#[0-9a-fA-F]{6}")

KITTY_ANSI_NAMES = [
    "black",
    "red",
    "green",
    "yellow",
    "blue",
    "magenta",
    "cyan",
    "white",
    "bright black",
    "bright red",
    "bright green",
    "bright yellow",
    "bright blue",
    "bright magenta",
    "bright cyan",
    "bright white",
]


# --- color helpers ---------------------------------------------------------


def rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def sgr(fg: str | None = None, bg: str | None = None, attrs: tuple[str, ...] = ()) -> str:
    if not COLOR:
        return ""
    codes: list[str] = [str(SGR_ATTRS[a]) for a in attrs if a in SGR_ATTRS]
    if fg:
        codes.append("38;2;%d;%d;%d" % rgb(fg))
    if bg:
        codes.append("48;2;%d;%d;%d" % rgb(bg))
    if not codes:
        return ""
    return "\x1b[" + ";".join(codes) + "m"


def paint(
    text: str, fg: str | None = None, bg: str | None = None, attrs: tuple[str, ...] = ()
) -> str:
    start = sgr(fg, bg, attrs)
    return f"{start}{text}\x1b[0m" if start else text


def swatch(hex_value: str, size: int = 3) -> str:
    return paint("█" * size, fg=hex_value)


def sample(hex_value: str, text: str = "sample", bg: str | None = None) -> str:
    return paint(f" {text} ", fg=hex_value, bg=bg)


# --- file readers ----------------------------------------------------------


def read(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return None


def parse_base16(path: Path) -> dict[str, object]:
    """Return slots, foreground, background, and cursor from a base16 shell file."""
    text = read(path)
    if text is None:
        return {"slots": [], "foreground": None, "background": None, "cursor": None}
    slots: list[dict[str, str]] = []
    variables = {"foreground": None, "background": None, "cursor": None}
    slot_re = re.compile(
        r'^color(\d{2})="([0-9a-fA-F]{2})/([0-9a-fA-F]{2})/([0-9a-fA-F]{2})"\s*(?:#\s*(.*))?$'
    )
    var_re = re.compile(
        r'^color_(foreground|background|cursor)="([0-9a-fA-F]{2})/([0-9a-fA-F]{2})/([0-9a-fA-F]{2})"'
    )
    for line in text.splitlines():
        if match := slot_re.match(line):
            slots.append(
                {
                    "name": f"color{match.group(1)}",
                    "hex": f"#{match.group(2)}{match.group(3)}{match.group(4)}".lower(),
                    "note": (match.group(5) or "").strip(),
                }
            )
        elif match := var_re.match(line):
            variables[match.group(1)] = (
                f"#{match.group(2)}{match.group(3)}{match.group(4)}".lower()
            )
    return {"slots": slots, **variables}


def parse_kitty(path: Path) -> dict[str, str]:
    text = read(path)
    values: dict[str, str] = {}
    if text is None:
        return values
    key_re = re.compile(r"^([a-z0-9_]+)\s+(#[0-9a-fA-F]{6})$")
    for line in text.splitlines():
        if match := key_re.match(line.strip()):
            values[match.group(1)] = match.group(2).lower()
    return values


def parse_vim(path: Path) -> list[dict[str, object]]:
    """Parse highlight groups from either supported colorscheme layout.

    `base16-remarkable-light.vim` calls `s:hi()` with literal hex values.
    The vendored base16-vim schemes call `<sid>hi()` with `s:gui00` and
    `s:cterm00` variables, so resolve those first.
    """
    text = read(path)
    if text is None:
        return []
    call_re = re.compile(r"^call\s+(?:s:hi|<sid>hi)\(\s*(.*?)\s*\)\s*$")
    gui_var_re = re.compile(r'^let s:gui([0-9A-Fa-f]{2})\s*=\s*"([0-9a-fA-F]{6})"')
    cterm_var_re = re.compile(r'^let s:cterm([0-9A-Fa-f]{2})\s*=\s*"([^"]*)"')
    arg_var_re = re.compile(r"^s:(gui|cterm)([0-9A-Fa-f]{2})$")
    gui_vars: dict[str, str] = {}
    cterm_vars: dict[str, str] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if match := gui_var_re.match(stripped):
            gui_vars[match.group(1).upper()] = f"#{match.group(2).lower()}"
        elif match := cterm_var_re.match(stripped):
            cterm_vars[match.group(1).upper()] = match.group(2)

    def resolve(token: str) -> str | None:
        token = token.strip().strip('"\'')
        if not token:
            return None
        if re.fullmatch(r"[0-9a-fA-F]{6}", token):
            return f"#{token.lower()}"
        if match := arg_var_re.match(token):
            lookup = gui_vars if match.group(1) == "gui" else cterm_vars
            return lookup.get(match.group(2).upper())
        return None

    def resolve_cterm(token: str) -> str | None:
        token = token.strip().strip('"\'')
        if not token:
            return None
        if token.isdigit():
            return token
        if match := arg_var_re.match(token):
            return cterm_vars.get(match.group(2).upper())
        return None

    groups: list[dict[str, object]] = []
    lines = text.splitlines()
    for index, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('"'):
            heading_text = stripped.lstrip('"').strip()
            following = next((item.strip() for item in lines[index + 1 :] if item.strip()), "")
            if heading_text and call_re.match(following):
                groups.append({"heading": heading_text})
            continue
        match = call_re.match(stripped)
        if not match:
            continue
        arguments = [item.strip() for item in match.group(1).split(",")]
        if len(arguments) < 6:
            continue
        name, guifg, guibg, ctermfg, ctermbg, attr = arguments[:6]
        groups.append(
            {
                "name": name.strip('"\''),
                "fg": resolve(guifg),
                "bg": resolve(guibg),
                "ctermfg": resolve_cterm(ctermfg),
                "ctermbg": resolve_cterm(ctermbg),
                "attr": attr.strip('"\''),
            }
        )
    return groups


def parse_btop(path: Path) -> dict[str, str]:
    text = read(path)
    values: dict[str, str] = {}
    if text is None:
        return values
    key_re = re.compile(r'^theme\[([a-z_]+)\]="(#[0-9a-fA-F]{6})"')
    for line in text.splitlines():
        if match := key_re.match(line.strip()):
            values[match.group(1)] = match.group(2).lower()
    return values


def parse_gitconfig(path: Path) -> dict[str, dict[str, str]]:
    text = read(path)
    sections: dict[str, dict[str, str]] = {}
    if text is None:
        return sections
    current = "delta"
    sections[current] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(("#", ";")):
            continue
        if stripped.startswith("[") and stripped.endswith("]"):
            match = re.match(r'^\[(.+?)(?:\s+"(.+)")?\]$', stripped)
            if match:
                current = match.group(2) or match.group(1)
                sections.setdefault(current, {})
            continue
        match = re.match(r"^(\S+)\s*=\s*(.*)$", stripped)
        if match:
            sections.setdefault(current, {})[match.group(1)] = match.group(2).strip().strip('"')
    return sections


def parse_style(value: str | None) -> dict[str, object]:
    """Split a delta style value into colors and attributes."""
    colors: list[str] = []
    attrs: list[str] = []
    for token in (value or "").split():
        if HEX_RE.fullmatch(token):
            colors.append(token.lower())
        else:
            attrs.append(token.lower())
    return {
        "fg": colors[0] if colors else None,
        "bg": colors[1] if len(colors) > 1 else None,
        "attrs": tuple(attrs),
    }


def resolve_pi(value: str, variables: dict[str, str]) -> str | None:
    seen: set[str] = set()
    while value in variables and value not in seen:
        seen.add(value)
        value = variables[value]
    return value.lower() if HEX_RE.fullmatch(value) else None


def load_pi(path: Path) -> dict[str, object] | None:
    text = read(path)
    if text is None:
        return None
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return None
    raw_vars = data.get("vars", {}) or {}
    variables = {key: str(value) for key, value in raw_vars.items()}
    colors = {
        key: resolve_pi(str(value), variables)
        for key, value in (data.get("colors", {}) or {}).items()
    }
    exported = {
        key: str(value).lower()
        for key, value in (data.get("export", {}) or {}).items()
    }
    return {
        "name": data.get("name", path.stem),
        "vars": {k: str(v).lower() for k, v in variables.items()},
        "colors": colors,
        "export": exported,
    }


def read_jq_colors() -> str | None:
    text = read(REPO_ROOT / "homelander/.bashrc/jq-colors.bash")
    if text is None:
        return None
    match = re.search(r'^export JQ_COLORS="([^"]*)"', text, re.MULTILINE)
    return match.group(1) if match else None


def active_theme() -> str | None:
    text = read(HOME / ".config/env-ubuntu/color-theme")
    return text.strip().splitlines()[0] if text and text.strip() else None


# --- rendering helpers -----------------------------------------------------


def heading(title: str, note: str = "") -> None:
    rule = "─" * max(4, 74 - len(title))
    line = f"\n── {title} {rule}"
    print(paint(line, fg=BASE["accent"], attrs=("bold",)))
    if note:
        print(paint(f"   {note}", fg=BASE["muted"]))


def field(label: str, value: str, width: int = 22) -> str:
    return f"   {paint(label.ljust(width), fg=BASE['muted'])}{value}"


def relative(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path).replace(str(HOME), "~")


def theme_files(theme: str) -> dict[str, Path | None]:
    spec = THEMES[theme]
    return {
        key: (REPO_ROOT / str(spec[key]) if spec.get(key) else None)
        for key in ("palette", "kitty", "git", "vim", "pi", "btop")
    }


# --- sections --------------------------------------------------------------


def section_palette(files: dict[str, Path | None], pal: dict[str, object]) -> None:
    path = files["palette"]
    heading("base16 palette", f"{relative(path)}" if path else "missing")
    slots = pal.get("slots") or []
    if not slots:
        print(paint("   no palette slots found", fg=BASE["error"]))
        return
    background = pal.get("background") or BASE["panel"]
    slot_note_width = max([len(str(slot.get("note") or "")) for slot in slots] + [1]) + 2
    note_pad = " " * slot_note_width
    for slot in slots:
        hex_value = str(slot["hex"])
        note = str(slot.get("note") or "")
        print(
            f"   {swatch(hex_value, 4)} {paint(hex_value, fg=hex_value)}  "
            f"{str(slot['name']).ljust(9)} {note.ljust(slot_note_width)}"
            f"{sample(hex_value, 'the quick brown fox', bg=str(background))}"        )
    for key in ("foreground", "background", "cursor"):
        hex_value = pal.get(key) or ""
        if hex_value:
            print(
                f"   {swatch(hex_value, 4)} {paint(hex_value, fg=hex_value)}  "
                f"{key.ljust(9)} {note_pad}"
                f"{sample(hex_value, 'the quick brown fox', bg=str(background))}"
            )


def section_kitty(files: dict[str, Path | None]) -> None:
    path = files["kitty"]
    heading("kitty", relative(path) if path else "missing")
    if not path:
        return
    values = parse_kitty(path)
    if not values:
        print(paint("   no colors found", fg=BASE["error"]))
        return
    background = values.get("background", BASE["panel"])
    for key in ("background", "foreground", "cursor", "cursor_text_color"):
        hex_value = values.get(key)
        if hex_value:
            print(
                field(key, f"{swatch(hex_value)} {hex_value}  ")
                + sample(hex_value, "terminal text", bg=background)
            )
    for key in ("selection_foreground", "selection_background"):
        hex_value = values.get(key)
        if hex_value:
            foreground = values.get("selection_foreground")
            print(
                field(key, f"{swatch(hex_value)} {hex_value}")
                + paint("  selected ", fg=foreground, bg=hex_value)
            )
    for index in range(16):
        key = f"color{index}"
        hex_value = values.get(key)
        if not hex_value:
            continue
        name = KITTY_ANSI_NAMES[index]
        print(
            field(name, f"{key.ljust(7)} {swatch(hex_value)} {hex_value}  ")
            + sample(hex_value, "Aa 0123", bg=background)
        )
    active_fg = values.get("active_tab_foreground")
    active_bg = values.get("active_tab_background")
    if active_bg:
        print(
            field("active tab", f"{active_bg} on {active_fg}")
            + paint(" active tab ", fg=active_fg, bg=active_bg)
            + paint(
                " inactive tab ",
                fg=values.get("inactive_tab_foreground"),
                bg=values.get("inactive_tab_background"),
            )
        )


def section_git(files: dict[str, Path | None]) -> None:
    path = files["git"]
    heading("git delta", relative(path) if path else "missing")
    if not path:
        return
    sections = parse_gitconfig(path)
    delta = sections.get("delta", {})
    line_numbers = sections.get("unobtrusive-line-numbers", {})
    decorations = sections.get("decorations", {})

    def style(name: str, values: dict[str, str] = delta) -> dict[str, object]:
        return parse_style(values.get(name))

    def show(label: str, text: str, parsed: dict[str, object]) -> None:
        hexes = " ".join(str(parsed[key]) for key in ("fg", "bg") if parsed[key])
        attrs = ",".join(parsed["attrs"])  # type: ignore[arg-type]
        detail = " ".join(part for part in (hexes, attrs) if part) or "(terminal default)"
        body = paint(text, fg=parsed["fg"], bg=parsed["bg"], attrs=parsed["attrs"])  # type: ignore[arg-type]
        print(f"   {paint(label.ljust(16), fg=BASE['muted'])}{body}")
        print(paint(f"   {'':16}{detail}", fg=BASE["dim"]))

    show("file header", "f  src/theme.py", style("file-style", decorations))
    show("hunk header", "@@ -1,3 +1,3 @@  def apply(theme):", style("hunk-header-decoration-style", decorations))
    show("minus line", "-    palette = 'old'", style("minus-style"))
    show("minus emphasis", "-    palette = 'old' ", style("minus-emph-style"))
    show("plus line", "+    palette = 'new'", style("plus-style"))
    show("plus emphasis", "+    palette = 'new' ", style("plus-emph-style"))
    left = style("line-numbers-left-style", line_numbers)
    zero = style("line-numbers-zero-style", line_numbers)
    right = style("line-numbers-right-style", line_numbers)
    gutter = (
        paint("  1 ", fg=left["fg"], bg=left["bg"])
        + paint(" 2 │", fg=zero["fg"], bg=zero["bg"])
        + paint("│ ", fg=right["fg"], bg=right["bg"])
    )
    detail = " ".join(
        f"{part}={style_value['fg']}"
        for part, style_value in (("left", left), ("zero", zero), ("right", right))
        if style_value["fg"]
    )
    print(f"   {paint('line numbers'.ljust(16), fg=BASE['muted'])}{gutter}")
    print(paint(f"   {'':16}{detail}", fg=BASE["dim"]))


def section_vim(files: dict[str, Path | None], pal: dict[str, object]) -> None:
    path = files["vim"]
    heading("vim", relative(path) if path else "missing")
    if not path:
        return
    background = pal.get("background") or BASE["panel"]
    groups = parse_vim(path)
    if not groups:
        print(paint("   no highlight groups found", fg=BASE["error"]))
        return
    for group in groups:
        if "heading" in group:
            title = str(group["heading"])
            if title:
                print(paint(f"   -- {title}", fg=BASE["muted"]))
            continue
        foreground = str(group["fg"]) if group["fg"] else None
        group_bg = str(group["bg"]) if group["bg"] else str(background)
        attrs: tuple[str, ...] = ()
        if group["attr"] and group["attr"] != "none":
            attrs = tuple(str(group["attr"]).split(","))
        hexes = " ".join(
            part
            for part in (
                f"fg={foreground}" if foreground else "",
                f"bg={group['bg']}" if group["bg"] else "",
                f"gui={group['attr']}" if group["attr"] and group["attr"] != "none" else "",
                f"cterm={group['ctermfg'] or '-'}/{group['ctermbg'] or '-'}",
            )
            if part
        )
        body = paint(str(group["name"]).ljust(16), fg=foreground, bg=group_bg, attrs=attrs)
        print(f"   {body}{paint(hexes, fg=BASE['dim'])}")


def section_pi(
    files: dict[str, Path | None], spec: dict[str, str | None], pal: dict[str, object]
) -> None:
    path = files["pi"]
    if not path:
        heading("pi", f"built-in {spec['pi_name']} theme (no repo file)")
        return
    heading("pi", relative(path))
    data = load_pi(path)
    if data is None:
        print(paint("   could not parse theme file", fg=BASE["error"]))
        return
    background = pal.get("background") or BASE["panel"]
    print(paint(f"   name {data['name']}", fg=BASE["muted"]))
    print(paint("   -- vars", fg=BASE["muted"]))
    for name, hex_value in data["vars"].items():  # type: ignore[union-attr]
        print(
            field(name, f"{swatch(str(hex_value))} {hex_value}  ")
            + sample(str(hex_value), "Aa", bg=str(background))
        )
    print(paint("   -- colors", fg=BASE["muted"]))
    for name, hex_value in data["colors"].items():  # type: ignore[union-attr]
        if not hex_value:
            continue
        print(
            field(name, f"{swatch(str(hex_value))} {hex_value}  ", width=24)
            + paint(" chip ", fg=str(background), bg=str(hex_value))
            + sample(str(hex_value), "Aa", bg=str(background))
        )
    if data["export"]:  # type: ignore[union-attr]
        print(paint("   -- export", fg=BASE["muted"]))
        for name, hex_value in data["export"].items():  # type: ignore[union-attr]
            print(
                field(name, f"{swatch(str(hex_value))} {hex_value}  ")
                + paint(" page ", fg=None, bg=str(hex_value))
            )


def find_bat() -> str | None:
    """Debian and Ubuntu ship bat as batcat, because bat is taken."""
    return shutil.which("bat") or shutil.which("batcat")


def section_bat(spec: dict[str, str | None]) -> None:
    name = str(spec["bat"])
    binary = find_bat()
    heading("bat", f"theme: {name}" + (f" · {binary}" if binary else ""))
    if not binary:
        print(paint("   bat and batcat are not installed", fg=BASE["muted"]))
        return
    snippet = (
        '# sample for theme preview\n'
        'def greet(name: str) -> str:\n'
        '    return f"hello {name}"  # 42\n'
    )
    with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False, encoding="utf-8") as handle:
        handle.write(snippet)
        temp_path = handle.name
    try:
        result = subprocess.run(
            [
                binary,
                f"--theme={name}",
                "--style=plain",
                f"--color={'always' if COLOR else 'never'}",
                "--paging=never",
                temp_path,
            ],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        result = None
    finally:
        Path(temp_path).unlink(missing_ok=True)
    if result is None or result.returncode != 0:
        message = (result.stderr.strip() if result else "") or "unknown error"
        print(paint(f"   could not run {binary}: {message}", fg=BASE["error"]))
        return
    for line in result.stdout.splitlines():
        print(f"   {line}")


def section_jq() -> None:
    colors = read_jq_colors()
    heading("jq", f"JQ_COLORS={colors}" if colors else "JQ_COLORS not found")
    if not colors:
        return
    if not shutil.which("jq"):
        print(paint("   jq is not installed", fg=BASE["muted"]))
        return
    payload = json.dumps(
        {
            "null": None,
            "false": False,
            "true": True,
            "number": 42,
            "string": "text",
            "array": [1, 2],
            "object": {"key": "value"},
        }
    )
    command = ["jq", "."]
    if COLOR:
        command = ["jq", "--color-output", "."]
    try:
        result = subprocess.run(
            command,
            input=payload,
            capture_output=True,
            text=True,
            env={**os.environ, "JQ_COLORS": colors},
            timeout=10,
        )
    except (OSError, subprocess.SubprocessError):
        result = None
    if result is None or result.returncode != 0:
        print(paint("   could not run jq", fg=BASE["error"]))
        return
    for line in result.stdout.splitlines():
        print(f"   {line}")


def state_line(mark: str, color: str, label: str, status: str, detail: str) -> None:
    print(
        f"   {paint(mark.ljust(2), fg=color)} "
        f"{paint(label.ljust(9), fg=BASE['muted'])} "
        f"{paint(status.ljust(8), fg=color)} {detail}"
    )


def applied_path(tracked: Path) -> Path:
    """Map a linked homelander file to the path homelinker creates for it."""
    try:
        return HOME / tracked.relative_to(REPO_ROOT / "homelander/_home")
    except ValueError:
        return tracked


def section_btop(files: dict[str, Path | None], pal: dict[str, object]) -> None:
    path = files["btop"]
    heading("btop", relative(path) if path else "missing")
    if not path:
        return
    values = parse_btop(path)
    if not values:
        print(paint("   no theme keys found", fg=BASE["error"]))
        return
    background = pal.get("background") or BASE["panel"]
    items: dict[str, dict[str, str]] = {}
    for key, hex_value in values.items():
        base, _, part = key.partition("_")
        if part in ("start", "mid", "end"):
            items.setdefault(base, {})[part] = hex_value
        else:
            items.setdefault(key, {"value": hex_value})
    for name, parts in items.items():
        if "value" in parts:
            hex_value = parts["value"]
            print(
                field(name, f"{swatch(hex_value)} {hex_value}  ", width=16)
                + sample(hex_value, "Aa", bg=str(background))
            )
            continue
        stops = [parts[part] for part in ("start", "mid", "end") if part in parts]
        bar = "".join(paint("███", fg=stop) for stop in stops)
        print(field(name, f"{bar}  {' '.join(stops)}", width=16))


def section_applied(theme: str, files: dict[str, Path | None]) -> None:
    current = active_theme()
    note = f"active theme file reports: {current or 'none'}"
    if current and current != theme:
        note += f" (not {theme})"
    heading("applied state", note)
    # These two are rendered copies, because an app rewrites them in place.
    generated = {
        "kitty": HOME / ".config/env-ubuntu/kitty-theme.conf",
        "git": HOME / ".config/env-ubuntu/git-theme.gitconfig",
        "btop": HOME / ".config/btop/themes" / f"env-ubuntu-{theme}.theme",
    }
    for label in ("palette", "kitty", "git", "vim", "pi", "btop"):
        tracked = files[label]
        if tracked is None:
            state_line("·", BASE["dim"], label, "skipped", "no tracked file")
            continue
        applied = generated.get(label) or applied_path(tracked)
        if not applied.exists():
            state_line("–", BASE["muted"], label, "missing", relative(applied))
            continue
        try:
            same = tracked.read_bytes() == applied.read_bytes()
        except OSError:
            same = False
        if same:
            state_line("✔", BASE["ok"], label, "same", relative(applied))
        else:
            state_line("✘", BASE["error"], label, "differs", relative(applied))


def section_off_palette(files: dict[str, Path | None], pal: dict[str, object]) -> None:
    known = {str(slot["hex"]) for slot in pal.get("slots") or []}  # type: ignore[union-attr]
    known |= {
        str(pal[key])
        for key in ("foreground", "background", "cursor")
        if pal.get(key)
    }
    heading("off-palette colors", "hex values that the base16 palette does not define")
    found = False
    for label, path in files.items():
        if path is None or not path.exists():
            continue
        text = read(path) or ""
        extra = sorted({value.lower() for value in HEX_RE.findall(text)} - known)
        if extra:
            found = True
            print(f"   {paint(label.ljust(8), fg=BASE['muted'])}{' '.join(extra)}")
    if not found:
        print(paint("   every color comes from the palette", fg=BASE["ok"]))


# --- entry point -----------------------------------------------------------


COLOR = False
BASE = {
    "accent": "#8ab4f8",
    "muted": "#8a8a8a",
    "dim": "#6f6f6f",
    "ok": "#6cc07a",
    "error": "#e06c75",
    "panel": "#1b1b1b",
}


def main(argv: list[str]) -> int:
    global COLOR

    parser = argparse.ArgumentParser(
        description="Print every env-ubuntu theme surface in the terminal.",
    )
    parser.add_argument("theme", nargs="*", help="theme names to render (default: active theme)")
    parser.add_argument("--all", action="store_true", help="render every known theme")
    parser.add_argument("--no-color", action="store_true", help="print hex values without escapes")
    args = parser.parse_args(argv)

    COLOR = not args.no_color and not os.environ.get("NO_COLOR") and sys.stdout.isatty()

    names = list(args.theme)
    if args.all:
        names = list(THEMES)
    if not names:
        names = [active_theme() or "default"]

    unknown = [name for name in names if name not in THEMES]
    if unknown:
        parser.error(
            f"unknown theme: {', '.join(unknown)} (known: {', '.join(THEMES)})"
        )

    for index, theme in enumerate(names):
        spec = THEMES[theme]
        files = theme_files(theme)
        pal = parse_base16(files["palette"]) if files["palette"] else {"slots": []}
        if index:
            print()
        print(paint(f"env-ubuntu theme preview · {theme} ({spec['mode']})", fg=BASE["accent"], attrs=("bold",)))
        print(paint(f"   repo {REPO_ROOT}", fg=BASE["muted"]))
        section_palette(files, pal)
        section_kitty(files)
        section_vim(files, pal)
        section_git(files)
        section_pi(files, spec, pal)
        section_btop(files, pal)
        section_bat(spec)
        section_jq()
        section_applied(theme, files)
        section_off_palette(files, pal)

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
