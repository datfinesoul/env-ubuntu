#!/usr/bin/env bash
# Starship directory display, relative to the immediate superproject when present.
#
# Uninstall (from the repository root):
# 1. Edit homelander/_home/.config/starship.toml:
#    - Remove the top-level `format` override (restores Starship's default).
#    - Remove [custom.super_root] and [custom.repo_path], including their options.
#    - Remove `disabled = true` from [directory]; keep its other options.
#      In particular, truncate_to_repo = false restores normal full paths.
# 2. Delete this script: rm scripts/starship-repo-path.bash
# The next prompt uses the restored built-in directory module. No shell restart
# is required. Do not reset unrelated configuration changes.
set -o errexit -o nounset -o pipefail

starship_repo_path() {
    local current root parent path prefix
    local mode=${1:-path}
    local is_super=false
    local -a parts
    current=$(pwd -P)
    if root=$(git rev-parse --show-toplevel 2>/dev/null); then
        parent=$(git rev-parse --show-superproject-working-tree 2>/dev/null) || parent=''
        root=${parent:-$root}
        root=$(cd -- "$root" && pwd -P)
        if [[ -n $parent ]] || git config --file "$root/.gitmodules" --get-regexp '^submodule\..*\.path$' >/dev/null 2>&1; then
            is_super=true
        fi
    fi
    if [[ $mode == super-root ]]; then
        [[ $is_super == false ]] || printf '↳/%s' "${root##*/}"
        return 0
    fi
    if [[ $is_super == true ]]; then
        case "$current" in
            "$root") path='' ;;
            "$root"/*) path="/${current#"$root"/}" ;;
            *) path=$current ;;
        esac
    else
        path=$current
        if [[ -n ${HOME:-} ]]; then
            case "$path" in
                "$HOME") path='~' ;;
                "$HOME"/*) path="~/${path#"$HOME"/}" ;;
            esac
        fi
        # Normal paths (including standalone repos) retain eight-component shortening.
        prefix=''
        [[ $path != /* ]] || prefix='/'
        IFS='/' read -r -a parts <<< "${path#/}"
        if (( ${#parts[@]} > 8 )); then
            parts=("${parts[@]:${#parts[@]}-8}")
            prefix='.../'
        fi
        path=$(IFS='/'; printf '%s' "${parts[*]}")
        path="$prefix$path"
    fi
    printf '%s' "$path"
    [[ -w . ]] || printf ' 🔒'
    return 0
}

starship_repo_path "$@"
