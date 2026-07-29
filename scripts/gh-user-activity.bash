#!/usr/bin/env bash
#
# gh-user-activity.bash — High-level snapshot of a GitHub user's issue and PR
# activity over a recent time window.
#
# In one sentence: given a GitHub username, it lists every issue and pull
# request that user participated in — tagged with *how* they participated
# (authored, assigned, mentioned, commented, reviewed, review-requested) —
# updated within the last N days, and prints a compact, skimmable report.
#
# Strategy: GitHub search can't tell you *why* an item matched, only that it
# did. So instead of one `--involves` query, we run one targeted search per
# participation role (--author, --assignee, --mentions, --commenter, and
# --reviewed-by for PRs) and merge the results by URL, unioning the roles. An
# item you both authored and reviewed shows up once, tagged with both roles.
# Bonus: `--involves` alone misses reviews entirely, so the per-role approach
# is also more complete.
#
# REVIEW REQUESTS: --review-requested is passive (someone asked *them* to
# review), not something they did, so it's off by default. With
# --review-requested we run a 6th search and list PRs whose ONLY role is
# review-requested in a separate section — a clean "still waiting on you"
# queue. Anything they've also touched stays in the main lists instead.
#
# COST NOTE: this is 5 search calls per run (6 with --review-requested). The
# search endpoint is rate-limited separately (~30 requests/min), so a single
# user is cheap, but don't loop this over hundreds of users without pacing.
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
#   ./gh-user-activity.bash USERNAME [--days N] [--limit N] [--review-requested]
#                                    [--json] [-o OUTFILE]
#
# Examples:
#   ./gh-user-activity.bash datfinesoul
#   ./gh-user-activity.bash datfinesoul --days 14 --review-requested
#   ./gh-user-activity.bash datfinesoul --json -o activity.json
#
# Output: by default a human-readable report on stdout, each item tagged with
# a `roles` list. With --json, a JSON array of the raw items (each with a
# `roles` array) instead. All log/progress lines are timestamped and go to
# stderr, so stdout stays clean and pipeable.
#
# Compatibility: Linux and macOS. Requires: gh, jq.

set -euo pipefail

# ---- defaults -------------------------------------------------------------
USERNAME=""
DAYS=7
LIMIT=200
WANT_JSON=0
WANT_REVIEW_REQ=0
OUTFILE=""

# ---- helpers --------------------------------------------------------------
log() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

fmt_dur() {
  local s=$1 h m
  h=$(( s / 3600 )); m=$(( (s % 3600) / 60 )); s=$(( s % 60 ))
  if   (( h > 0 )); then printf '%dh %dm %ds' "$h" "$m" "$s"
  elif (( m > 0 )); then printf '%dm %ds' "$m" "$s"
  else                   printf '%ds' "$s"; fi
}

# Epoch seconds -> UTC ISO-8601, portable across GNU and BSD/macOS date.
epoch_to_iso() {
  local e=$1
  if date -u -d "@0" +%Y >/dev/null 2>&1; then
    date -u -d "@${e}" +%Y-%m-%dT%H:%M:%SZ   # GNU
  else
    date -u -r "${e}" +%Y-%m-%dT%H:%M:%SZ     # BSD / macOS
  fi
}

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

Usage: gh-user-activity.bash USERNAME [--days N] [--limit N]
                                      [--review-requested] [--json] [-o FILE]

  USERNAME              GitHub login to inspect (required)
      --days N          Look back N days by updated-at (default: 7)
  -L, --limit N         Max items to fetch, up to 1000 (default: 200)
      --review-requested  Also list PRs awaiting the user's review (in their
                          own section; only those they haven't otherwise
                          touched). Adds one extra search.
      --json            Emit the raw JSON array instead of a report
  -o, --output FILE     Write output here (default: stdout)
  -h, --help            Show this help

Direct participation roles are: authored, assigned, mentioned, commented,
reviewed. "review-requested" is passive (someone asked them to review) and is
off by default; enable it with --review-requested. The window filters on
last-updated, not created.
USAGE
  exit "${1:-0}"
}

# ---- arg parsing ----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)              DAYS="$2"; shift 2 ;;
    -L|--limit)          LIMIT="$2"; shift 2 ;;
    --review-requested)  WANT_REVIEW_REQ=1; shift ;;
    --json)              WANT_JSON=1; shift ;;
    -o|--output)         OUTFILE="$2"; shift 2 ;;
    -h|--help)           usage 0 ;;
    -*)                  echo "Unknown option: $1" >&2; usage 1 ;;
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
START=$SECONDS

# ---- color setup ----------------------------------------------------------
# Only colorize a report going to an interactive terminal. Honor NO_COLOR,
# and never colorize JSON or file output (would corrupt it).
C_RESET=""; C_BOLD=""; C_DIM=""; C_OPEN=""; C_CLOSED=""; C_MERGED=""
if [[ -z "${NO_COLOR:-}" && "$WANT_JSON" -eq 0 && -z "$OUTFILE" && -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_OPEN=$'\033[32m'; C_CLOSED=$'\033[31m'; C_MERGED=$'\033[35m'
fi

# ---- rate limit BEFORE ----------------------------------------------------
# `gh search` uses the REST *search* endpoint, which has its own budget
# (typically 30 requests/min) separate from core and GraphQL.
RL_JSON=$(gh api rate_limit --jq '.resources.search')
RL_BEFORE=$(jq -r '.remaining' <<<"$RL_JSON")
RL_LIMIT=$(jq -r '.limit' <<<"$RL_JSON")
RL_RESET=$(epoch_to_iso "$(jq -r '.reset' <<<"$RL_JSON")")
log "Rate limit (search) BEFORE: ${RL_BEFORE}/${RL_LIMIT} requests remaining (resets at ${RL_RESET})"

# ---- fetch ----------------------------------------------------------------
log "Searching activity for '$USERNAME' updated since ${CUTOFF} (last ${DAYS}d, limit ${LIMIT})"

JSON_FIELDS='number,title,url,isPullRequest,state,repository,author,createdAt,updatedAt,commentsCount,labels'

# One search per participation role. Fields: ROLE, gh subcommand, and the flag
# that scopes the search to USER. The "issues" subcommand uses --include-prs so
# a role can match both issues and PRs; review roles are PR-only by nature.
# review-requested is passive, so it's only fetched when explicitly requested.
ROLE_SPECS=(
  "authored:issues:--author"
  "assigned:issues:--assignee"
  "mentioned:issues:--mentions"
  "commented:issues:--commenter"
  "reviewed:prs:--reviewed-by"
)
(( WANT_REVIEW_REQ )) && ROLE_SPECS+=( "review-requested:prs:--review-requested" )

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
HIT_LIMIT=0

for spec in "${ROLE_SPECS[@]}"; do
  IFS=':' read -r role sub flag <<<"$spec"

  args=( "$sub" "$flag" "$USERNAME" --updated ">=${CUTOFF}" --sort updated --limit "$LIMIT" --json "$JSON_FIELDS" )
  [[ "$sub" == "issues" ]] && args+=( --include-prs )

  resp="$(gh search "${args[@]}")"
  n=$(jq 'length' <<<"$resp")
  (( n >= LIMIT )) && HIT_LIMIT=1
  log "  ${role}: ${n} match(es)"

  # Tag every item with this role, force isPullRequest true for PR-only
  # searches, and append one object per line for later merging.
  jq -c --arg role "$role" --argjson isprs "$([[ "$sub" == prs ]] && echo true || echo false)" '
    .[] | . + {role: $role, isPullRequest: (.isPullRequest // $isprs)}
  ' <<<"$resp" >> "$TMP"
done

# Merge by URL, unioning roles so each item appears once with all its roles.
DATA="$(jq -s '
  group_by(.url)
  | map( (.[0] | del(.role)) + { roles: (map(.role) | unique) } )
' "$TMP")"

COUNT=$(jq 'length' <<<"$DATA")
log "Fetched ${COUNT} distinct item(s)."
if (( HIT_LIMIT )); then
  log "Warning: a role search hit the --limit of ${LIMIT}; results may be truncated. Raise --limit or shorten --days."
fi

# ---- emit -----------------------------------------------------------------
emit() {
  if [[ -n "$OUTFILE" ]]; then cat > "$OUTFILE"; log "Wrote output -> ${OUTFILE}"; else cat; fi
}

# Rate limit AFTER + timing. Called on every exit path so the accounting is
# always reported.
report_finish() {
  local after consumed elapsed
  after=$(gh api rate_limit --jq '.resources.search.remaining')
  consumed=$(( RL_BEFORE - after ))
  log "Rate limit (search) AFTER:  ${after}/${RL_LIMIT} requests remaining (consumed ${consumed} this run)"
  elapsed=$(( SECONDS - START ))
  log "Done. Reported ${COUNT} item(s) for @${USERNAME} in $(fmt_dur "$elapsed")."
}

if (( WANT_JSON )); then
  jq '.' <<<"$DATA" | emit
  report_finish
  exit 0
fi

# Human-readable report. Normalise repo/author (search may return null author
# for ghosted accounts). "Direct" items (any of authored/assigned/mentioned/
# commented/reviewed) drive the PR and Issue sections; PRs whose ONLY role is
# review-requested are broken out into their own section. Color codes are
# passed in and are empty strings when color is disabled.
jq -r --arg user "$USERNAME" --arg cutoff "$CUTOFF" --arg days "$DAYS" \
      --arg showrr "$WANT_REVIEW_REQ" \
      --arg reset "$C_RESET" --arg bold "$C_BOLD" --arg dim "$C_DIM" \
      --arg open "$C_OPEN" --arg closed "$C_CLOSED" --arg merged "$C_MERGED" '
  def repo:   (.repository.nameWithOwner // "unknown");
  def who:    (.author.login // "ghost");
  def roles:  (.roles | join(","));
  def st:     (.state | ascii_downcase);
  def stcol:  ({open: $open, closed: $closed, merged: $merged}[st] // "");
  def direct: any(.roles[]; IN("authored","assigned","mentioned","commented","reviewed"));
  def line:
    "  [\(stcol)\(st)\($reset)] \(repo)#\(.number)  \($bold)\(.title)\($reset)",
    "        \($dim)\(roles) · by @\(who) · updated \(.updatedAt[0:10]) · \(.url)\($reset)";

  ([.[] | select(direct and .isPullRequest)])        as $prs
  | ([.[] | select(direct and (.isPullRequest|not))]) as $issues
  | ([.[] | select(direct|not)])                      as $rr
  | ([($prs[],$issues[],$rr[]) | repo] | unique)      as $repos

  | "GitHub activity for @\($user) — last \($days)d (updated since \($cutoff))",
    "=========================================================",
    "  \(($prs|length)+($issues|length)) direct item(s): \($prs|length) PR(s), \($issues|length) issue(s)\(if $showrr=="1" then " · \($rr|length) awaiting review" else "" end) across \($repos|length) repo(s)",
    "",
    (if ($prs | length) > 0 then
       "Pull Requests",
       "-------------",
       ( $prs | sort_by(.updatedAt) | reverse | .[] | line )
     else empty end),
    (if ($prs | length) > 0 and ($issues | length) > 0 then "" else empty end),
    (if ($issues | length) > 0 then
       "Issues",
       "------",
       ( $issues | sort_by(.updatedAt) | reverse | .[] | line )
     else empty end),
    (if $showrr=="1" and ($rr | length) > 0 then
       "",
       "Review Requested (awaiting @\($user), not yet touched)",
       "-----------------------------------------------------",
       ( $rr | sort_by(.updatedAt) | reverse | .[] | line )
     else empty end),
    (if (($prs|length)+($issues|length)+($rr|length)) == 0 then "  (no activity in this window)" else empty end)
' <<<"$DATA" | emit

report_finish
