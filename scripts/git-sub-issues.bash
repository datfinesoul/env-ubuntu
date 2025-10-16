#!/usr/bin/env bash
repo=$1
issue=$2
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
