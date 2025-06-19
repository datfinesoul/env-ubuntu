ccode () {
	local selected_model
	local models_file="$HOME/.claude-code-models"

	# Check Pre-Requisites
	if ! command -v pnpm >/dev/null 2>&1 && ! command -v npm >/dev/null 2>&1; then
		>&2 echo "[✘] Neither pnpm nor npm found."
		return 1
	fi
	if ! command -v fzf >/dev/null 2>&1; then
		>&2 echo "[✘] fzf not found."
		return 1
	fi

	# AWS assume role and setup
	if command -v assume >/dev/null 2>&1; then
		>&2 echo "[i] Assuming AWS role..."
		. assume -r us-west-2
	else
		>&2 echo "[!] 'assume' command not found. Skipping AWS role assumption."
	fi

	# delete the models file if older than a day
	if [[ -f "$models_file" ]]; then
		find "$(dirname "$models_file")" \
			-name "$(basename "$models_file")" \
			-mtime +1 -delete 2>/dev/null
		if [[ ! -f "$models_file" ]]; then
			>&2 echo "[!] Deleted older $models_file cache"
		fi
	fi
	if [[ ! -f "$models_file" ]]; then
		aws bedrock list-foundation-models \
			--region us-west-2 \
			--query 'modelSummaries[?providerName==`Anthropic`].modelId | sort(@)' \
			--output json \
			| jq -r '.[]' \
			> "$models_file"
	fi

	# Install claude-code using pnpm first, fallback to npm
	if command -v pnpm >/dev/null 2>&1; then
		pnpm install -g @anthropic-ai/claude-code
	else
		npm install -g @anthropic-ai/claude-code
	fi

	# Use fzf to select model from the file
	selected_model=$(cat "$models_file" | fzf --prompt="Select Claude model: " --height=10 --layout=reverse --no-multi)
	if [[ -z "$selected_model" ]]; then
		>&2 echo "[✘] No model selected. Exiting."
		return 1
	fi
	export ANTHROPIC_MODEL="us.$selected_model"

	# Set up environment variables
	export CLAUDE_CODE_USE_BEDROCK=1
	export CLAUDE_CODE_MAX_OUTPUT_TOKENS=10240
	unset DISABLE_PROMPT_CACHING
	unset AWS_PROFILE

	# Launch claude
	>&2 echo "[i] Starting Claude Code..."
	>&2 echo "[i] Environment:"
	>&2 echo "[i]   ANTHROPIC_MODEL=$ANTHROPIC_MODEL"
	>&2 echo "[i]   CLAUDE_CODE_USE_BEDROCK=$CLAUDE_CODE_USE_BEDROCK"
	>&2 echo "[i]   AWS Region: us-west-2"
	>&2 echo ""

	if command -v pnpm >/dev/null 2>&1; then
		claude mcp add opentofu -- pnpm dlx @opentofu/opentofu-mcp-server
	else
		claude mcp add opentofu -- npx @opentofu/opentofu-mcp-server
	fi
	if docker images mcp/aws-documentation:latest &> /dev/null; then
		claude mcp add aws-docs -- docker run \
			--rm --interactive \
			--env FASTMCP_LOG_LEVEL=ERROR \
			--env AWS_DOCUMENTATION_PARTITION=aws \
			mcp/aws-documentation:latest
	fi
	claude "$@"
}
