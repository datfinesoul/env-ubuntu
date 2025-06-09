#!/usr/bin/env bash
# shellcheck disable=SC1091
source "$(dirname "${0}")/_core.bash"

# use pnpm at home
npm install -g @anthropic-ai/claude-code
export ANTHROPIC_MODEL=us....
export CLAUDE_CODE_USE_BEDROCK=1
unset DISABLE_PROMPT_CACHING

assume -r us-west-2 io/dev/ai ; unset AWS_PROFILE; claude
