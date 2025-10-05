#!/usr/bin/env bash
git reset -- "$(git rev-parse --show-toplevel)/homelander/_home/.gitconfig" > /dev/null
git checkout -- "$(git rev-parse --show-toplevel)/homelander/_home/.gitconfig" > /dev/null
