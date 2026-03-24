#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Validate required arguments
if [[ $# -lt 2 ]]; then
	echo "Usage: $(basename "$0") <repo> <issue>" >&2
	echo "Example: $(basename "$0") owner/repo 123" >&2
	exit 1
fi

repo=$1
issue=$2

# Validate repo format (owner/repo)
if [[ ! "$repo" =~ ^[^/]+/[^/]+$ ]]; then
	echo "Error: Repository must be in 'owner/repo' format" >&2
	exit 1
fi

# Validate issue is a number
if [[ ! "$issue" =~ ^[0-9]+$ ]]; then
	echo "Error: Issue must be a number" >&2
	exit 1
fi

# Check for gh command
if ! command -v gh &> /dev/null; then
	echo "Error: 'gh' (GitHub CLI) is not installed or not in PATH" >&2
	exit 1
fi

issue_id="$(gh issue view "$issue" --repo "$repo" --json id --jq '.id')"

# Then get sub-issue titles
gh api graphql -H "GraphQL-Features: sub_issues" -f query="
query {
	node(id: \"$issue_id\") {
		... on Issue {
			subIssues(first: 100) {
				nodes {
					title
				}
			}
		}
	}
}" --jq '.data.node.subIssues.nodes[].title' \
	| sed 's/^/- /'
