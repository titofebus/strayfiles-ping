#!/bin/bash
# SessionStart hook for strayfiles-ping
# Checks if the strayfiles-ping binary is installed and reachable.
# Never blocks the session — only provides guidance via systemMessage.

# Check if strayfiles-ping is in PATH
if command -v strayfiles-ping >/dev/null 2>&1; then
  echo '{"continue": true}'
  exit 0
fi

# Check the default install location
if [ -x "${HOME}/.local/bin/strayfiles-ping" ]; then
  cat <<'EOF'
{
  "continue": true,
  "systemMessage": "The strayfiles-ping binary was found at ~/.local/bin/strayfiles-ping but is not in PATH. The MCP server may fail to start. Suggest the user add it to their PATH:\n\nexport PATH=\"$HOME/.local/bin:$PATH\"\n\nAdd this line to ~/.bashrc, ~/.zshrc, or the appropriate shell profile."
}
EOF
  exit 0
fi

# Binary not found anywhere
cat <<'EOF'
{
  "continue": true,
  "systemMessage": "The strayfiles-ping binary is not installed. Ping notifications will not be available until it is installed. If the user wants to receive notifications from AI agents, suggest they install it:\n\ncurl -fsSL https://strayfiles.com/ping-install.sh | sh\n\nThen restart Claude Code for the MCP server to connect."
}
EOF
exit 0
