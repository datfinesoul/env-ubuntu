#!/usr/bin/env bash
#
# index-org-prs.sh — Index open PRs across the repos in a GitHub org.
#
# Strategy: a nested GraphQL query, paginated manually over the repo list,
# ordered by PUSHED_AT (newest first). By default it only scans repos pushed
# within the last 15 days and STOPS as soon as it crosses that boundary, so
# on a 2,000-repo org you typically touch a few pages instead of ~40.
#
# Each in-window repo brings back up to 100 open PRs in the same round trip.
# Repos with >100 open PRs are truncated at 100 (by design); the script warns
# you which ones were capped so you can follow up.
#
# COST NOTE: the big GraphQL point driver is nested connections. Labels are
# OFF by default because labels(first:20) under pullRequests(first:100) forces
# the cost formula to assume PAGE_SIZE x 100 PR nodes, pushing each page from
# ~1 point to ~50. Add --labels only if you need them.
#
# About --page-size (-n): how many repos are fetched per round trip.
#   Higher  -> fewer requests, but heavier server-side work per query and more
#              timeout risk. Lower -> safer, more round trips. 25-50 is the
#              sweet spot.
#
# About --since-days: size of the pushed-at window (default 15). Use 0 (or
#   --all) to scan every repo with no early break. NOTE: this filters on repo
#   push activity, so an open-but-untouched PR on an otherwise dormant repo
#   will be skipped. Widen the window or use --all if you need the full set.
#
# Usage:
#   ./index-org-prs.sh ORG [-o OUTFILE] [-n PAGE_SIZE] [--since-days N]
#                          [--all] [--labels] [--include-archived]
#
# Examples:
#   ./index-org-prs.sh acme-corp
#   ./index-org-prs.sh acme-corp --since-days 30 --labels -o prs.json
#   ./index-org-prs.sh acme-corp --all
#
# Output: a JSON array of PR objects, each annotated with its repository,
# written to OUTFILE if given, otherwise stdout. All log/progress lines are
# timestamped and go to stderr, so stdout stays clean JSON.
#
# Compatibility: Linux and macOS. Requires: gh, jq, and Bash 4+ (for
# mapfile). macOS ships Bash 3.2, so use a Homebrew Bash there if needed.

set -euo pipefail

# ---- defaults -------------------------------------------------------------
ORG=""
OUTFILE=""
PAGE_SIZE=50
SINCE_DAYS=15
WANT_LABELS=0
INCLUDE_ARCHIVED=0

# ---- helpers --------------------------------------------------------------
log() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

fmt_dur() {
  local s=$1 h m
  h=$(( s / 3600 )); m=$(( (s % 3600) / 60 )); s=$(( s % 60 ))
  if   (( h > 0 )); then printf '%dh %dm %ds' "$h" "$m" "$s"
  elif (( m > 0 )); then printf '%dm %ds' "$m" "$s"
  else                   printf '%ds' "$s"; fi
}

# UTC ISO-8601 timestamp N days ago, portable across GNU and BSD/macOS date.
iso_days_ago() {
  local days=$1
  if date -u -d "@0" +%Y >/dev/null 2>&1; then
    date -u -d "${days} days ago" +%Y-%m-%dT%H:%M:%SZ   # GNU
  else
    date -u -v-"${days}"d +%Y-%m-%dT%H:%M:%SZ           # BSD / macOS
  fi
}

usage() {
  cat >&2 <<'USAGE'
Usage: index-org-prs.sh ORG [-o OUTFILE] [-n PAGE_SIZE] [--since-days N]
                            [--all] [--labels] [--include-archived]

  ORG                     GitHub organization login (required)
  -o, --output FILE       Write JSON array here (default: stdout)
  -n, --page-size N       Repos per request, 25-50 recommended (default: 50)
      --since-days N       Only repos pushed within N days (default: 15)
      --all                Scan all repos, no pushed-at window / early break
      --labels             Include PR labels (raises GraphQL point cost a lot)
      --include-archived   Include archived repos (default: skip them)
  -h, --help              Show this help

Repos are ordered by PUSHED_AT desc and scanning stops at the window edge,
so a small window means far fewer requests and points.
USAGE
  exit "${1:-0}"
}

# ---- arg parsing ----------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)         OUTFILE="$2"; shift 2 ;;
    -n|--page-size)      PAGE_SIZE="$2"; shift 2 ;;
    --since-days)        SINCE_DAYS="$2"; shift 2 ;;
    --all)               SINCE_DAYS=0; shift ;;
    --labels)            WANT_LABELS=1; shift ;;
    --include-archived)  INCLUDE_ARCHIVED=1; shift ;;
    -h|--help)           usage 0 ;;
    -*)                  echo "Unknown option: $1" >&2; usage 1 ;;
    *)
      if [[ -z "$ORG" ]]; then ORG="$1"; shift
      else echo "Unexpected argument: $1" >&2; usage 1; fi
      ;;
  esac
done

[[ -z "$ORG" ]] && { echo "Error: ORG is required." >&2; usage 1; }
[[ "$SINCE_DAYS" =~ ^[0-9]+$ ]] || { echo "Error: --since-days must be a non-negative integer." >&2; usage 1; }

# ---- preflight checks -----------------------------------------------------
command -v gh >/dev/null 2>&1 || { echo "Error: gh CLI not found on PATH." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq not found on PATH." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Error: not authenticated. Run 'gh auth login'." >&2; exit 1; }

# GraphQL wants a Boolean or null (null = no archived filter)
ARCHIVED_FILTER="false"
[[ "$INCLUDE_ARCHIVED" -eq 1 ]] && ARCHIVED_FILTER="null"

# Empty cutoff = no window (scan all). Otherwise an ISO-8601 UTC boundary.
# String comparison of fixed-width UTC timestamps is chronological.
CUTOFF=""
if (( SINCE_DAYS > 0 )); then CUTOFF="$(iso_days_ago "$SINCE_DAYS")"; fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

START=$SECONDS

# ---- the page query -------------------------------------------------------
# __LABELS__ is substituted below depending on --labels.
read -r -d '' PAGE_QUERY <<'GQL' || true
query($org: String!, $pageSize: Int!, $isArchived: Boolean, $endCursor: String) {
  rateLimit { limit cost remaining used resetAt }
  organization(login: $org) {
    repositories(first: $pageSize, after: $endCursor, isArchived: $isArchived,
                 orderBy: {field: PUSHED_AT, direction: DESC}) {
      pageInfo { hasNextPage endCursor }
      nodes {
        nameWithOwner
        pushedAt
        pullRequests(states: OPEN, first: 100, orderBy: {field: UPDATED_AT, direction: DESC}) {
          totalCount
          nodes {
            number title url isDraft createdAt updatedAt
            author { login }
            headRefName baseRefName
            __LABELS__
          }
        }
      }
    }
  }
}
GQL

if (( WANT_LABELS )); then
  PAGE_QUERY=${PAGE_QUERY//__LABELS__/labels(first: 20) { nodes { name } }}
else
  PAGE_QUERY=${PAGE_QUERY//__LABELS__/}
fi

# Flatten in-window repos -> one PR object per line. labels key only appears
# when it was actually fetched.
FLATTEN_JQ='
  .data.organization.repositories.nodes[]
  | select((.pushedAt // "") >= $cutoff)
  | .nameWithOwner as $repo
  | .pushedAt as $pushed
  | .pullRequests.totalCount as $total
  | .pullRequests.nodes[]
  | ({
      repository: $repo,
      repoPushedAt: $pushed,
      repoOpenPrCount: $total,
      truncated: ($total > 100),
      number, title, url, isDraft, createdAt, updatedAt,
      author: (.author.login // null),
      head: .headRefName,
      base: .baseRefName
    } + (if .labels then {labels: [.labels.nodes[].name]} else {} end))
'

# ---- rate limit + repo count BEFORE --------------------------------------
if [[ -n "$CUTOFF" ]]; then
  log "Indexing open PRs for org '$ORG' (page size: $PAGE_SIZE, window: ${SINCE_DAYS}d since ${CUTOFF}, labels: $([[ $WANT_LABELS -eq 1 ]] && echo on || echo off))"
else
  log "Indexing open PRs for org '$ORG' (page size: $PAGE_SIZE, window: all repos, labels: $([[ $WANT_LABELS -eq 1 ]] && echo on || echo off))"
fi

PRE=$(gh api graphql -F org="$ORG" -F isArchived="$ARCHIVED_FILTER" -f query='
  query($org: String!, $isArchived: Boolean) {
    rateLimit { limit remaining used resetAt }
    organization(login: $org) {
      repositories(isArchived: $isArchived) { totalCount }
    }
  }')

if jq -e '.errors' <<<"$PRE" >/dev/null 2>&1; then
  log "GraphQL error:"; jq -r '.errors[].message' <<<"$PRE" >&2; exit 1
fi
if [[ "$(jq -r '.data.organization' <<<"$PRE")" == "null" ]]; then
  log "Error: organization '$ORG' not found (or it's a user, not an org)."; exit 1
fi

TOTAL_REPOS=$(jq -r '.data.organization.repositories.totalCount' <<<"$PRE")
RL_BEFORE=$(jq -r '.data.rateLimit.remaining' <<<"$PRE")
RL_LIMIT=$(jq -r '.data.rateLimit.limit' <<<"$PRE")
RL_RESET=$(jq -r '.data.rateLimit.resetAt' <<<"$PRE")
log "Rate limit (GraphQL) BEFORE: ${RL_BEFORE}/${RL_LIMIT} points remaining (resets at ${RL_RESET})"
if [[ -n "$CUTOFF" ]]; then
  log "Org has ${TOTAL_REPOS} repo(s); scanning newest-first until the ${SINCE_DAYS}-day boundary."
else
  log "Repositories to scan: ${TOTAL_REPOS}"
fi

# ---- manual pagination loop ----------------------------------------------
cursor=""
page=0
scanned=0       # repos actually fetched
matched=0       # repos within the window (contributed PRs)

while :; do
  page=$(( page + 1 ))

  args=( -F org="$ORG" -F pageSize="$PAGE_SIZE" -F isArchived="$ARCHIVED_FILTER" )
  [[ -n "$cursor" ]] && args+=( -f endCursor="$cursor" )

  resp=$(gh api graphql "${args[@]}" -f query="$PAGE_QUERY")

  if jq -e '.errors' <<<"$resp" >/dev/null 2>&1; then
    log "GraphQL error on page $page:"; jq -r '.errors[].message' <<<"$resp" >&2; exit 1
  fi

  jq -c --arg cutoff "$CUTOFF" "$FLATTEN_JQ" <<<"$resp" >> "$TMP"

  page_scanned=$(jq -r '.data.organization.repositories.nodes | length' <<<"$resp")
  page_matched=$(jq -r --arg cutoff "$CUTOFF" '[.data.organization.repositories.nodes[] | select((.pushedAt // "") >= $cutoff)] | length' <<<"$resp")
  # crossed = this page contains a repo older than the window boundary
  crossed=$(jq -r --arg cutoff "$CUTOFF" '[.data.organization.repositories.nodes[] | (.pushedAt // "") < $cutoff] | any' <<<"$resp")

  scanned=$(( scanned + page_scanned ))
  matched=$(( matched + page_matched ))
  rl_now=$(jq -r '.data.rateLimit.remaining' <<<"$resp")
  prs_so_far=$(wc -l < "$TMP" | tr -d ' ')

  if [[ -n "$CUTOFF" ]]; then
    log "Page ${page}: scanned ${scanned} repo(s), ${matched} in window | PRs so far: ${prs_so_far} | rate remaining: ${rl_now}"
  else
    pct=0; (( TOTAL_REPOS > 0 )) && pct=$(( scanned * 100 / TOTAL_REPOS ))
    log "Page ${page}: repos ${scanned}/${TOTAL_REPOS} (${pct}%) | PRs so far: ${prs_so_far} | rate remaining: ${rl_now}"
  fi

  # Early break: we crossed the pushed-at boundary (only when windowing).
  if [[ -n "$CUTOFF" && "$crossed" == "true" ]]; then
    log "Reached the ${SINCE_DAYS}-day boundary; stopping early."
    break
  fi

  has_next=$(jq -r '.data.organization.repositories.pageInfo.hasNextPage' <<<"$resp")
  cursor=$(jq -r '.data.organization.repositories.pageInfo.endCursor' <<<"$resp")
  [[ "$has_next" == "true" ]] || break
done

# ---- warn about truncated repos ------------------------------------------
mapfile -t CAPPED < <(jq -r 'select(.truncated) | .repository' "$TMP" | sort -u)
if [[ ${#CAPPED[@]} -gt 0 ]]; then
  log "Warning: ${#CAPPED[@]} repo(s) have >100 open PRs and were capped at 100:"
  printf '  - %s\n' "${CAPPED[@]}" >&2
fi

# ---- assemble final JSON array -------------------------------------------
TOTAL_PRS=$(wc -l < "$TMP" | tr -d ' ')
if [[ -n "$OUTFILE" ]]; then
  jq -s '.' "$TMP" > "$OUTFILE"
  log "Wrote ${TOTAL_PRS} open PR(s) -> ${OUTFILE}"
else
  jq -s '.' "$TMP"
fi

# ---- rate limit AFTER + timing -------------------------------------------
POST=$(gh api graphql -f query='{ rateLimit { limit remaining used resetAt } }')
RL_AFTER=$(jq -r '.data.rateLimit.remaining' <<<"$POST")
CONSUMED=$(( RL_BEFORE - RL_AFTER ))
log "Rate limit (GraphQL) AFTER:  ${RL_AFTER}/${RL_LIMIT} points remaining (consumed ${CONSUMED} this run)"

ELAPSED=$(( SECONDS - START ))
log "Done. Indexed ${TOTAL_PRS} open PR(s) from ${matched} in-window repo(s) (scanned ${scanned}) in $(fmt_dur "$ELAPSED")."
