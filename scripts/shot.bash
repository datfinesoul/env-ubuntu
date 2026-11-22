#!/usr/bin/env bash
# Screenshot inbox for flameshot.
#
#   shot.bash [full] [label] [--dir DIR] [--dry-run]
#
# Captures the whole desktop with flameshot and moves the image into a shared
# inbox that any agent on this machine can read. Prints the absolute path.
#
# flameshot on GNOME Wayland ignores -p and writes ~/Pictures/Screenshot*.png,
# so the image is located by a marker file, waited on until its size is stable,
# and then moved into the inbox.
#
# region and window are refused: flameshot runs under Xwayland here and cannot
# grab an interactive selection.
set -uo pipefail

poll=0.25
find_tries=40
settle_tries=20

die() {
  printf 'shot: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'DOC'
usage: shot.bash [full] [label] [--dir DIR] [--dry-run]

  full        whole desktop, the only supported mode and the default
  label       optional name suffix, sanitized to [A-Za-z0-9._-]

options:
  --dir DIR   destination directory, overrides SHOT_DIR
  --dry-run   print the destination path without capturing
  -h, --help  show this help

region and window are not supported: flameshot runs under Xwayland and cannot
grab an interactive selection.

Destination: SHOT_DIR, else ${XDG_DATA_HOME:-$HOME/.local/share}/screenshots
DOC
}

default_dir() {
  printf '%s\n' "${SHOT_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/screenshots}"
}

# flameshot writes to the XDG pictures directory, which need not be ~/Pictures.
pictures_dir() {
  local file="${XDG_CONFIG_HOME:-${HOME}/.config}/user-dirs.dirs"
  local value=""
  if [[ -r "$file" ]]; then
    value="$(sed -n 's/^XDG_PICTURES_DIR="\(.*\)"$/\1/p' "$file" | head -1)"
    value="${value//\$HOME/${HOME}}"
  fi
  [[ -n "$value" ]] || value="${HOME}/Pictures"
  printf '%s\n' "$value"
}

sanitize_label() {
  local value="$1"
  value="${value//[^A-Za-z0-9._-]/-}"
  while [[ "$value" == *--* ]]; do
    value="${value//--/-}"
  done
  value="${value#-}"
  value="${value%-}"
  value="${value:0:40}"
  value="${value%-}"
  printf '%s\n' "$value"
}

# Absolute form of a path without creating it, so --dry-run has no side effects.
absolute_dir() {
  local dir="$1"
  local cwd
  if [[ -d "$dir" ]]; then
    ( cd -- "$dir" && pwd )
    return 0
  fi
  case "$dir" in
    /*)
      printf '%s\n' "${dir%/}"
      ;;
    *)
      cwd="$(pwd)" || return 1
      printf '%s\n' "${cwd}/${dir#./}"
      ;;
  esac
}

# flameshot shows a desktop toast for every capture. Add the opt-out once and
# never override a value the user already set.
quiet_flameshot() {
  local ini="${XDG_CONFIG_HOME:-${HOME}/.config}/flameshot/flameshot.ini"
  local tmp
  grep -qs '^showDesktopNotification' "$ini" && return 0
  mkdir -p -- "$(dirname "$ini")" 2>/dev/null || return 0
  tmp="${ini}.tmp.$$"
  if grep -qs '^\[General\]' "$ini"; then
    awk '!done && /^\[General\]$/ { print; print "showDesktopNotification=false"; done=1; next } { print }' \
      -- "$ini" > "$tmp" || { rm -f -- "$tmp"; return 0; }
  else
    {
      printf '[General]\n'
      printf 'showDesktopNotification=false\n'
      if [[ -s "$ini" ]]; then cat -- "$ini"; fi
    } > "$tmp" || { rm -f -- "$tmp"; return 0; }
  fi
  mv -f -- "$tmp" "$ini" || rm -f -- "$tmp"
}

next_destination() {
  local dir="$1"
  local label="$2"
  local stem dest count
  stem="$(date +%Y%m%d-%H%M%S)"
  [[ -n "$label" ]] && stem="${stem}-${label}"
  dest="${dir}/${stem}.png"
  count=1
  while [[ -e "$dest" ]]; do
    count=$((count + 1))
    [[ "$count" -le 9999 ]] || die "too many files named ${stem}"
    dest="${dir}/${stem}-${count}.png"
  done
  printf '%s\n' "$dest"
}

file_size() {
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1" 2>/dev/null || printf '0\n'
}

# Wait for flameshot to drop a new, non-empty, settled image in the pictures
# directory. flameshot never exits on its own, so the caller kills it.
wait_for_capture() {
  local dir="$1"
  local marker="$2"
  local tries="$find_tries"
  local settle="$settle_tries"
  local new=""
  local size=0
  local prev=-1

  while [[ "$tries" -gt 0 ]]; do
    new="$(find "$dir" -maxdepth 1 -type f -name 'Screenshot*.png' -size +0c -newer "$marker" 2>/dev/null | head -1)"
    [[ -n "$new" ]] && break
    sleep "$poll"
    tries=$((tries - 1))
  done

  while [[ -n "$new" && "$settle" -gt 0 ]]; do
    size="$(file_size "$new")"
    [[ "$size" -gt 0 && "$size" == "$prev" ]] && break
    prev="$size"
    sleep "$poll"
    settle=$((settle - 1))
  done

  printf '%s\n' "$new"
}

capture_full() {
  local dest="$1"
  local dir marker new fpid
  dir="$(pictures_dir)"
  marker="$(mktemp "${TMPDIR:-/tmp}/shot-marker-XXXXXX")" || die "cannot create a marker file"

  quiet_flameshot
  flameshot full >/dev/null 2>&1 &
  fpid=$!

  new="$(wait_for_capture "$dir" "$marker")"

  kill "$fpid" 2>/dev/null
  wait "$fpid" 2>/dev/null
  rm -f -- "$marker"

  [[ -n "$new" ]] || die "flameshot produced no image in ${dir}"
  [[ -s "$new" ]] || die "flameshot left an empty file: ${new}"

  mkdir -p -- "$(dirname "$dest")" || die "cannot create ${dest%/*}"
  mv -f -- "$new" "$dest" || die "cannot move ${new} to ${dest}"
  [[ -s "$dest" ]] || die "destination is empty: ${dest}"
  printf '%s\n' "$dest"
}

main() {
  local mode="full"
  local label=""
  local dir
  local dest
  local dry_run=0

  dir="$(default_dir)"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      full)
        mode="full"
        shift
        ;;
      region|window)
        die "$1 is not supported: flameshot runs under Xwayland and cannot grab an interactive selection"
        ;;
      --dir)
        [[ $# -ge 2 ]] || die "--dir needs a directory"
        dir="$2"
        [[ -n "$dir" ]] || die "--dir needs a directory"
        shift 2
        ;;
      --dir=*)
        dir="${1#--dir=}"
        [[ -n "$dir" ]] || die "--dir needs a directory"
        shift
        ;;
      --dry-run|-n)
        dry_run=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        die "unknown option: $1"
        ;;
      *)
        [[ -z "$label" ]] || die "unexpected argument: $1"
        label="$1"
        shift
        ;;
    esac
  done
  [[ $# -eq 0 ]] || die "unexpected argument: $1"

  mode="${mode:-full}"
  label="$(sanitize_label "$label")"
  dir="$(absolute_dir "$dir")"
  dest="$(next_destination "$dir" "$label")"

  if [[ "$dry_run" -eq 1 ]]; then
    printf '%s\n' "$dest"
    exit 0
  fi

  command -v flameshot >/dev/null 2>&1 || die "flameshot is not installed"
  capture_full "$dest"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
