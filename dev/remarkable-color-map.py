#!/usr/bin/env python3
"""Render a per-app color map for the reMarkable theme.

Reads the same palette and app settings that `color_theme remarkable` applies.
Run it from any directory: python3 dev/remarkable-color-map.py
It writes remarkable-color-map.png next to this script.
Requires Pillow and the DejaVu fonts.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FONT_DIR = "/usr/share/fonts/truetype/dejavu"
def font(name, size):
    return ImageFont.truetype(f"{FONT_DIR}/{name}", size)

F_TITLE = font("DejaVuSans-Bold.ttf", 36)
F_SUB = font("DejaVuSans.ttf", 15)
F_SEC = font("DejaVuSans-Bold.ttf", 19)
F_SEC_DETAIL = font("DejaVuSansMono.ttf", 12)
F_NAME = font("DejaVuSans-Bold.ttf", 13)
F_META = font("DejaVuSansMono.ttf", 11)
F_SLOT = font("DejaVuSans.ttf", 12)
F_SAMPLE = font("DejaVuSansMono-Bold.ttf", 22)
F_NOTE = font("DejaVuSans.ttf", 13)

PAPER = "#e3e1da"
PAPER_RAISED = "#f2f0e9"
INK = "#292a28"
GRAY = "#686964"
DIM = "#777873"
RULE = "#c5c4bd"

MARGIN = 48
CARD_W, CARD_H = 160, 112
GAP_X, GAP_Y = 14, 16
COLS = 8
SWATCH_H = 56

# name, hex, palette slot
PALETTE = [
    ("ink", "#1f201e", "base00"),
    ("paper muted", "#d8d6cf", "base01"),
    ("selection", "#c5c4bd", "base02"),
    ("bright black", "#8a8b85", "base03"),
    ("dim gray", "#777873", "base04"),
    ("gray", "#686964", "base05"),
    ("paper raised", "#f2f0e9", "base06"),
    ("paper", "#e3e1da", "base07"),
    ("red", "#9c3d34", "base08"),
    ("orange", "#aa6025", "base09"),
    ("yellow", "#956600", "base0A"),
    ("green", "#377748", "base0B"),
    ("cyan", "#006f76", "base0C"),
    ("blue", "#326591", "base0D"),
    ("magenta", "#794982", "base0E"),
    ("brown", "#78473d", "base0F"),
]

KITTY_UI = [
    ("foreground", "#292a28", "fg *"),
    ("background", "#e3e1da", "bg *"),
    ("cursor", "#1f201e", "base00"),
    ("cursor text", "#f2f0e9", "base06"),
    ("selection fg", "#292a28", "fg"),
    ("selection bg", "#c5c4bd", "base02"),
    ("active tab fg", "#f2f0e9", "base06"),
    ("active tab bg", "#326591", "base0D"),
    ("inactive tab fg", "#686964", "base05"),
    ("inactive tab bg", "#d8d6cf", "base01"),
]

KITTY_ANSI = [
    ("ansi 0", "#1f201e", "black"),
    ("ansi 1", "#9c3d34", "base08"),
    ("ansi 2", "#377748", "base0B"),
    ("ansi 3", "#956600", "base0A"),
    ("ansi 4", "#326591", "base0D"),
    ("ansi 5", "#794982", "base0E"),
    ("ansi 6", "#006f76", "base0C"),
    ("ansi 7", "#686964", "base05"),
    ("ansi 8", "#8a8b85", "base03"),
    ("ansi 9", "#bd4034", "bright red"),
    ("ansi 10", "#359050", "bright green"),
    ("ansi 11", "#b57d00", "bright yellow"),
    ("ansi 12", "#2d7fb6", "bright blue"),
    ("ansi 13", "#9552a2", "bright magenta"),
    ("ansi 14", "#008790", "bright cyan"),
    ("ansi 15", "#3d3e3a", "bold ink"),
]

VIM_UI = [
    ("Normal fg", "#292a28", "fg *"),
    ("Normal bg", "#e3e1da", "terminal"),
    ("CursorLine", "#d8d6cf", "base01"),
    ("LineNr", "#8a8b85", "base03"),
    ("Visual", "#c5c4bd", "base02"),
    ("PmenuSel", "#326591", "base0D"),
    ("Search", "#b57d00", "bright yellow"),
    ("IncSearch", "#9c3d34", "base08"),
]

VIM_SYNTAX = [
    ("Comment", "#777873", "base04"),
    ("String", "#377748", "base0B"),
    ("Number", "#aa6025", "base09"),
    ("Function", "#326591", "base0D"),
    ("Keyword", "#794982", "base0E"),
    ("Type", "#956600", "base0A"),
    ("Constant", "#aa6025", "base09"),
    ("Special", "#006f76", "base0C"),
]

PI = [
    ("accent", "#326591", "base0D"),
    ("text", "#292a28", "ink"),
    ("muted", "#686964", "base05"),
    ("selectedBg", "#c5c4bd", "base02"),
    ("success", "#377748", "base0B"),
    ("error", "#9c3d34", "base08"),
    ("warning", "#956600", "base0A"),
    ("bashMode", "#956600", "base0A"),
    ("searchMatchBg", "#b5a879", "local value"),
    ("userMessageBg", "#d8d6cf", "base01"),
    ("toolSuccessBg", "#d3dfd2", "local value"),
    ("toolErrorBg", "#e3cfca", "local value"),
    ("mdHeading", "#326591", "base0D"),
    ("mdLink", "#2d7fb6", "bright blue"),
    ("mdCode", "#006f76", "base0C"),
    ("syntaxKeyword", "#794982", "base0E"),
    ("syntaxString", "#377748", "base0B"),
    ("syntaxVariable", "#aa6025", "base09"),
    ("thinkingMax", "#aa6025", "base09"),
]

GIT = [
    ("minus", "#9c3d34", "on #e3cfca"),
    ("minus emph", "#9c3d34", "on #d9b8b1"),
    ("plus", "#377748", "on #d3dfd2"),
    ("plus emph", "#377748", "on #bfd2bd"),
    ("line numbers", "#326591", "base0D"),
    ("file style", "#292a28", "ink"),
    ("file decoration", "#006f76", "base0C"),
    ("hunk decoration", "#686964", "base05"),
]

SECTIONS = [
    ("Base16 palette", "source of every color below · base16-remarkable.light.sh",
     [PALETTE], None),
    ("Kitty terminal", "themes/kitty/remarkable.conf  ·  * fg and bg override the palette",
     [KITTY_UI, KITTY_ANSI],
     "bat uses BAT_THEME=ansi, so it reads the same ANSI colors and needs no separate map."),
    ("Vim", "~/.vim/colors/base16-remarkable-light.vim",
     [VIM_UI, VIM_SYNTAX], None),
    ("Pi", "~/.pi/agent/themes/remarkable.json",
     [PI], None),
    ("Git delta", "themes/git/remarkable.gitconfig",
     [GIT], None),
]


def lum(hex_color):
    r, g, b = (int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5))
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def on_color(hex_color):
    return INK if lum(hex_color) > 0.28 else PAPER_RAISED


def grid_rows(items):
    return (len(items) + COLS - 1) // COLS


# ---- layout ---------------------------------------------------------------
TITLE_H = 150
SEC_HEAD_H = 46
NOTE_H = 30
FOOTER_H = 56

body_h = 0
for _name, _detail, grids, note in SECTIONS:
    body_h += SEC_HEAD_H
    for g in grids:
        body_h += grid_rows(g) * (CARD_H + GAP_Y)
    if note:
        body_h += NOTE_H

width = MARGIN * 2 + COLS * CARD_W + (COLS - 1) * GAP_X
height = TITLE_H + body_h + FOOTER_H

img = Image.new("RGB", (width, height), PAPER)
d = ImageDraw.Draw(img)

# ---- title ----------------------------------------------------------------
d.text((MARGIN, 40), "reMarkable theme color map", font=F_TITLE, fill=INK)
d.text((MARGIN, 86), "functions/color-theme.bash · color_theme remarkable · one palette, five app surfaces",
       font=F_SUB, fill=GRAY)
d.text((MARGIN, 112), "Each card shows the app role, the resolved hex value, and the palette slot it comes from.",
       font=F_NOTE, fill=DIM)

y = TITLE_H


def draw_card(x, y, item):
    name, color, slot = item
    d.rectangle([x, y, x + CARD_W, y + SWATCH_H], fill=color, outline=RULE)
    d.text((x + 10, y + 14), "Aa", font=F_SAMPLE, fill=on_color(color))
    d.text((x + 10, y + SWATCH_H + 8), name, font=F_NAME, fill=INK)
    d.text((x + 10, y + SWATCH_H + 28), color.upper(), font=F_META, fill=GRAY)
    d.text((x + 10, y + SWATCH_H + 44), slot, font=F_SLOT, fill=DIM)


for sec_name, sec_detail, grids, note in SECTIONS:
    d.text((MARGIN, y), sec_name, font=F_SEC, fill=INK)
    dw = d.textlength(sec_name, font=F_SEC)
    d.text((MARGIN + dw + 14, y + 6), sec_detail, font=F_SEC_DETAIL, fill=DIM)
    y += SEC_HEAD_H

    for items in grids:
        for i, item in enumerate(items):
            col = i % COLS
            row = i // COLS
            x = MARGIN + col * (CARD_W + GAP_X)
            cy = y + row * (CARD_H + GAP_Y)
            draw_card(x, cy, item)
        y += grid_rows(items) * (CARD_H + GAP_Y)

    if note:
        d.text((MARGIN, y + 2), note, font=F_NOTE, fill=GRAY)
        y += NOTE_H

# ---- footer ---------------------------------------------------------------
d.line([MARGIN, height - FOOTER_H + 4, width - MARGIN, height - FOOTER_H + 4], fill=RULE)
d.text((MARGIN, height - FOOTER_H + 16),
       "color_theme remarkable also writes ~/.config/env-ubuntu/kitty-theme.conf and git-theme.gitconfig from the tracked themes/ files.",
       font=F_NOTE, fill=GRAY)

out = Path(__file__).resolve().parent / "remarkable-color-map.png"
img.save(out)
print(f"{out} {img.size[0]}x{img.size[1]}")
