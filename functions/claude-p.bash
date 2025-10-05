alias claude-p=claude_p
claude_p () {
	# Check Pre-Requisites
	if ! command -v pnpm >/dev/null 2>&1 && ! command -v npm >/dev/null 2>&1; then
		>&2 echo "[✘] Neither pnpm nor npm found."
		return 1
	fi
	if ! command -v fzf >/dev/null 2>&1; then
		>&2 echo "[✘] fzf not found."
		return 1
	fi

	# Install claude-code using pnpm first, fallback to npm
	if command -v pnpm >/dev/null 2>&1; then
		pnpm install -g @anthropic-ai/claude-code
	else
		npm install -g @anthropic-ai/claude-code
	fi

	unset AWS_PROFILE

	>&2 echo "[i] Starting Claude Code..."

	if command -v pnpm >/dev/null 2>&1; then
		claude mcp add opentofu -- pnpm dlx @opentofu/opentofu-mcp-server
	else
		claude mcp add opentofu -- npx @opentofu/opentofu-mcp-server
	fi
	docker pull mcp/aws-documentation:latest
	claude mcp add aws-docs -- docker run \
		--rm \
		--interactive \
		--env FASTMCP_LOG_LEVEL=ERROR \
		--env AWS_DOCUMENTATION_PARTITION=aws \
		mcp/aws-documentation:latest
	#claude mcp add aws-cost -- docker run \
	#  --rm \
	#  --interactive \
	#  --env FASTMCP_LOG_LEVEL=ERROR \
	#  --env AWS_DOCUMENTATION_PARTITION=aws \
	#  --env AWS_ACCESS_KEY_ID \
	#  --env AWS_SECRET_ACCESS_KEY \
	#  --env AWS_SESSION_TOKEN \
	#  awslabs/cost-analysis-mcp-server:latest
	#claude mcp add aws-diagram -- docker run \
	#  --rm \
	#  --interactive \
	#  --env FASTMCP_LOG_LEVEL=ERROR \
	#  --env AWS_DOCUMENTATION_PARTITION=aws \
	#  mcp/aws-diagram:latest

	claude mcp add bookmark-manager -- docker run \
			--rm \
			--interactive \
			--volume ~/.bookmark-manager:/app/.data \
			mindriftfall2infinitepiio/bookmark-manager-mcp:latest

	claude "$@"
}
