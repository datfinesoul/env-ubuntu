#!/usr/bin/env bash
git reset -- "$(git rev-parse --show-toplevel)/homelander/_home/.gitconfig"
git checkout -- "$(git rev-parse --show-toplevel)/homelander/_home/.gitconfig"
