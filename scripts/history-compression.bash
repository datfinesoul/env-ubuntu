#!/usr/bin/env bash
set -euo pipefail

# Parse CLI flags
dry_run=true
for arg in "$@"; do
  case "$arg" in
    --no-dry-run) dry_run=false ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "unknown arg: $arg" >&2; exit 1 ;;
  esac
done

# Resolve and validate target history file
histfile="${HISTFILE:-$HOME/.bash_history}"
histdir="$(dirname "$histfile")"
stamp="$(date +%Y%m%d-%H%M%S)"

[[ -f "$histfile" ]] || { echo "no history file: $histfile" >&2; exit 1; }

# Stage a scratch file; cleanup is registered only when we actually mutate
tmp="$(mktemp /tmp/dedupe_history.XXXXXX)"
if ! $dry_run; then
  trap 'rm -f "$tmp"' EXIT
fi

# Collapse duplicates; keep each command's last occurrence and timestamp in file order.
awk '
/^#/ { ts=$0; next }
{
  # Ignore trailing blanks only on simple command lines with bare words.
  key=$0
  if (key ~ /^[[:alnum:]_.\/~-]+([[:blank:]]+[[:alnum:]_.\/~-]+)*[[:blank:]]+$/)
    sub(/[[:blank:]]+$/, "", key)
  order[++n]=$0
  keys[n]=key
  last_index[key]=n
  last_ts[key]=ts
}
END {
  for (i=1; i<=n; i++) {
    if (last_index[keys[i]] == i) {
      print last_ts[keys[i]]
      print order[i]
    }
  }
}
' "$histfile" > "$tmp"

# Measure how many lines the cleanup will remove
before=$(wc -l < "$histfile")
after=$(wc -l < "$tmp")
removed=$((before - after))

# Exit early when the file is already clean
if cmp -s "$histfile" "$tmp"; then
  echo "no duplicates found ($before lines)"
  exit 0
fi

# Default to a preview; only mutate when explicitly asked
echo "found $removed duplicate lines ($before -> $after)"

if $dry_run; then
  echo "dry run: pass --no-dry-run to apply"
  echo "diff $histfile $tmp"
  exit 0
fi

# Snapshot the original, then atomically swap in the deduped file
cp "$histfile" "$histdir/.bash_history.$stamp.bak"
mv "$tmp" "$histfile"
trap - EXIT
echo "backup: $histdir/.bash_history.$stamp.bak"

# When sourced, refresh the live shell's history
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  history -c && history -r "$histfile"
fi
