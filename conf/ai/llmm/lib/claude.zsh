#!/usr/bin/env zsh
# claude.zsh — launch Claude Code pointed at the local server.

# claude::launch <alias> <port> [claude args...]
claude::launch() {
  local alias="$1" port="$2"; shift 2
  exec env \
    ANTHROPIC_BASE_URL="http://127.0.0.1:$port" \
    ANTHROPIC_API_KEY="llama-cpp" \
    ANTHROPIC_AUTH_TOKEN="llama-cpp" \
    ANTHROPIC_DEFAULT_SONNET_MODEL="$alias" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$alias" \
    ANTHROPIC_DEFAULT_OPUS_MODEL="$alias" \
    CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1 \
    claude "$@"
}
