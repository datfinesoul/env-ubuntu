#!/usr/bin/env bash
#
# gh-user-activity.bash — High-level snapshot of a GitHub user's issue and PR
# activity over a recent time window.
#
# In one sentence: given a GitHub username, it lists every issue and pull
# request that user has been *involved* in (authored, assigned, mentioned, or
# commented on) that was updated within the last N days, and prints a compact,
# skimmable report.
#
# Strategy: a single `gh search issues` call with `--involves USER
# --include-prs --updated ">=CUTOFF"`. GitHub's issue search index already
# unions issues and pull requests, tagging each with `isPullRequest`, so one
# round trip gets both. "Involvement" is GitHub's own qualifier and covers
# authored / assigned / mentioned / commented — a good high-level proxy for
# "what has this person been touching lately".
#
# NOTE ON THE WINDOW: the filter is on *updated* time, not created time. A
# months-old issue that got a comment yesterday will (correctly) show up,
# because the point is recent activity, not recent creation.
#
# NOTE ON LIMITS: GitHub search returns at most 1000 results and rate-limits
# the search endpoint separately (~30 req/min). --limit caps how many items we
# pull; if you hit the cap the report says so, so you can narrow the window.
#
# Usage:
#   ./gh-user-activity.bash USERNAME [--days N] [--limit N] [--json]
#                                    [-o OUTFILE]
#
# Examples:
#   ./gh-user-activity.bash octocat
#   ./gh-user-activity.bash octocat --days 14
#   ./gh-user-activity.bash octocat --json -o activity.json
#
# Output: by default a human-readable report on stdout. With --json, a JSON
# array of the raw items instead. All log/progress lines are timestamped and
# go to stderr, so stdout stays clean and pipeable.
#
# Compatibility: Linux and macOS. Requires: gh, jq.

set -euo pipefail

# ---- defaults -------------------------------------------------------------
USERNAME=""
DAYS=7
LIMIT=200
WANT_JSON=0
OUTFILE=""

# ---- helpers --------------------------------------------------------------
log() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

# UTC ISO-8601 date (YYYY-MM-DD) N days ago, portable across GNU and BSD/macOS.
iso_days_ago() {
  local days=$1
  if date -u -d "@0" +%Y >/dev/null 2>&1; then
    date -u -d "${days} days ago" +%Y-%m-%d   # GNU
  else
    date -u -v-"${days}"d +%Y-%m-%d           # BSD / macOS
  fi
}

usage() {
  cat >&2 <<'USAGE'
High-level snapshot of a GitHub user's issue and PR activity over a recent
window. Lists everything they authored, were assigned, were mentioned in, or
commented on that was updated within the window.

Usage: gh-user-activity.bash USERNAME [--days N] [--limit N] [--json] [-o FILE]

  USERNAME              GitHub login to inspect (required)
      --days N          Look back N days by updated-at (default: 7)
  -L, --limit N         Max items to fetch, up to 1000 (default: 200)
      --json            Emit the raw JSON array instead of a report
  -o, --output FILE     Write output here (default: stdout)
  -h, --help            Show this help

"Involvement" is GitHub's own search qualifier: authored, assigned, mentioned,
or commented. The window filters on last-updated, not created.
USAGE
  exit "${1:-0}"
}

# ---- arg parsing ----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)          DAYS="$2"; shift 2 ;;
    -L|--limit)      LIMIT="$2"; shift 2 ;;
    --json)          WANT_JSON=1; shift ;;
    -o|--output)     OUTFILE="$2"; shift 2 ;;
    -h|--help)       usage 0 ;;
    -*)              echo "Unknown option: $1" >&2; usage 1 ;;
    *)
      if [[ -z "$USERNAME" ]]; then USERNAME="$1"; shift
      else echo "Unexpected argument: $1" >&2; usage 1; fi
      ;;
  esac
done

[[ -z "$USERNAME" ]] && { echo "Error: USERNAME is required." >&2; usage 1; }
[[ "$DAYS"  =~ ^[0-9]+$ ]] || { echo "Error: --days must be a non-negative integer." >&2; usage 1; }
[[ "$LIMIT" =~ ^[0-9]+$ ]] || { echo "Error: --limit must be a non-negative integer." >&2; usage 1; }

# ---- preflight checks -----------------------------------------------------
command -v gh >/dev/null 2>&1 || { echo "Error: gh CLI not found on PATH." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq not found on PATH." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Error: not authenticated. Run 'gh auth login'." >&2; exit 1; }

CUTOFF="$(iso_days_ago "$DAYS")"

# ---- fetch ----------------------------------------------------------------
log "Searching activity for '$USERNAME' updated since ${CUTOFF} (last ${DAYS}d, limit ${LIMIT})"

JSON_FIELDS='number,title,url,isPullRequest,state,repository,author,createdAt,updatedAt,commentsCount,labels'

DATA="$(gh search issues \
  --involves "$USERNAME" \
  --include-prs \
  --updated ">=${CUTOFF}" \
  --sort updated \
  --limit "$LIMIT" \
  --json "$JSON_FIELDS")"

COUNT=$(jq 'length' <<<"$DATA")
log "Fetched ${COUNT} item(s)."
if (( COUNT >= LIMIT )); then
  log "Warning: hit the --limit of ${LIMIT}; results may be truncated. Raise --limit or shorten --days."
fi

# ---- emit -----------------------------------------------------------------
emit() {
  if [[ -n "$OUTFILE" ]]; then cat > "$OUTFILE"; log "Wrote output -> ${OUTFILE}"; else cat; fi
}

if (( WANT_JSON )); then
  jq '.' <<<"$DATA" | emit
  exit 0
fi

# Human-readable report. Normalise repo/author (search may return null author
# for ghosted accounts) and split into PRs vs issues.
jq -r --arg user "$USERNAME" --arg cutoff "$CUTOFF" --arg days "$DAYS" '
  def repo: (.repository.nameWithOwner // "unknown");
  def who:  (.author.login // "ghost");

  ([.[] | select(.isPullRequest)]) as $prs
  | ([.[] | select(.isPullRequest | not)]) as $issues
  | ([.[] | repo] | unique) as $repos

  | "GitHub activity for @\($user) — last \($days)d (updated since \($cutoff))",
    "=========================================================",
    "  \(length) item(s): \($prs | length) PR(s), \($issues | length) issue(s) across \($repos | length) repo(s)",
    "",
    (if ($prs | length) > 0 then
       "Pull Requests",
       "-------------",
       ( $prs
         | sort_by(.updatedAt) | reverse
         | .[]
         | "  [\(.state | ascii_downcase)] \(repo)#\(.number)  \(.title)",
           "        by @\(who) · updated \(.updatedAt[0:10]) · \(.url)" )
     else empty end),
    (if ($prs | length) > 0 and ($issues | length) > 0 then "" else empty end),
    (if ($issues | length) > 0 then
       "Issues",
       "------",
       ( $issues
         | sort_by(.updatedAt) | reverse
         | .[]
         | "  [\(.state | ascii_downcase)] \(repo)#\(.number)  \(.title)",
           "        by @\(who) · updated \(.updatedAt[0:10]) · \(.url)" )
     else empty end),
    (if length == 0 then "  (no activity in this window)" else empty end)
' <<<"$DATA" | emit
