export PATH="$HOME/.local/share/npm-global/bin:$PATH"
key_to_add=~/.ssh/some_key
comment_in_key=<what you specified in -C option on the key creation>

# Start SSH agent only if we can't communicate with one
ssh-add -l &>/dev/null
agent_status=$?

if [ $agent_status -eq 2 ]; then
  # Exit code 2: Can't connect to agent - need to start one
  # First, try to find an existing agent socket
  for sock in /tmp/ssh-*/agent.*; do
    if [ -S "$sock" ]; then
      export SSH_AUTH_SOCK="$sock"
      if ssh-add -l &>/dev/null; then
        # Successfully connected to existing agent
        agent_status=$?
        break
      fi
    fi
  done

  # If still can't connect, kill old agents and start a new one
  if [ $agent_status -eq 2 ]; then
    pkill -u "$USER" ssh-agent 2>/dev/null
    eval $(ssh-agent -s)
    agent_status=1  # Set to 1 (no keys) so we add the key below
  fi
fi

# Add the key only if it's not already loaded
# Check by comparing the fingerprint or comment from ssh-add -l
if [ $agent_status -ne 0 ] || ! ssh-add -l 2>/dev/null | grep -q "$comment_in_key"; then
  ssh-add "$key_to_add"
fi
