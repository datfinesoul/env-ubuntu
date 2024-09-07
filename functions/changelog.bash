changelog() {
  gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /repos/{owner}/{repo}/releases \
    --jq '.[] | "\n## " + .tag_name + " - " + .published_at + " - " + .name + "\n\n" + .body'
}

