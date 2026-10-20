# Clone a GitHub repository and change the current shell's directory to it.
ghclone() {
    local url="${1:-}" owner repo dest path
    url="${url%/}"

    case "$url" in
        https://github.com/*) path="${url#https://github.com/}" ;;
        git@github.com:*) path="${url#git@github.com:}" ;;
        *) path="$url" ;;
    esac

    if [[ "$#" -ne 1 || ! "$path" =~ ^([A-Za-z0-9_-]+)/([A-Za-z0-9_.-]+)$ ]]; then
        echo "Usage: ghclone <https://github.com/owner/repo | git@github.com:owner/repo.git | owner/repo>" >&2
        return 1
    fi

    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]%.git}"
    if [[ -z "$repo" || "$repo" == . || "$repo" == .. ]]; then
        echo "Invalid repository name." >&2
        return 1
    fi
    dest="$HOME/github/$owner/$repo"

    if [[ -d "$dest" ]]; then
        cd "$dest"
        return $?
    fi

    command -v gh >/dev/null 2>&1 || {
        echo "ghclone requires the GitHub CLI (gh)." >&2
        return 1
    }

    mkdir -p "$HOME/github/$owner" &&
        gh repo clone "$url" "$dest" &&
        cd "$dest"
}
