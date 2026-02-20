# Strayfiles Ping

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Open source Claude Code plugin for native user interactions. Get instant responses from users while they're in another app. Native macOS dialogs for quick decisions, push notifications for when they're away.

## What It Does

- **Native dialogs**: Confirmation, choice, text input, multi-question wizards — rendered as native macOS dialogs
- **Push notifications**: Reach users on iOS and macOS apps when they're away from their computer (Pro)
- **Smart routing**: Automatically picks local dialog or remote push based on user presence (Pro)
- **Zero config**: Works immediately after install — no account needed for local dialogs

## Free vs Pro

| Capability | Free | Pro |
|---|---|---|
| Native macOS dialogs | Yes | Yes |
| All input types (confirmation, choice, text, etc.) | Yes | Yes |
| Snooze, feedback, history | Yes | Yes |
| Smart routing (auto local/remote) | — | Yes |
| Remote push notifications (iOS, macOS app) | — | Yes |
| Local auto-response queue | Yes | Yes |

## Installation

### Step 1: Install the binary

```bash
curl -fsSL https://strayfiles.com/ping-install.sh | sh
```

This installs only the Ping binaries needed for MCP (`strayfiles-ping` and
optional `strayfiles-dialog` on macOS), not the full macOS app bundle/DMG.

### Step 2: Add the MCP server to your agent

#### Claude Code

```bash
claude mcp add --transport stdio strayfiles-ping -- strayfiles-ping
```

Or use the plugin for auto-configuration (includes skills and prompts):

```bash
claude plugin install https://github.com/titofebus/strayfiles-ping.git
```

#### Codex

```bash
codex mcp add strayfiles-ping -- strayfiles-ping
```

#### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "strayfiles-ping": {
      "command": "strayfiles-ping"
    }
  }
}
```

#### Windsurf

Add to `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "strayfiles-ping": {
      "command": "strayfiles-ping"
    }
  }
}
```

#### VS Code

Add to `.vscode/mcp.json`:

```json
{
  "servers": {
    "strayfiles-ping": {
      "type": "stdio",
      "command": "strayfiles-ping"
    }
  }
}
```

#### Zed

Add to your Zed settings (`zed: open settings`):

```json
{
  "context_servers": {
    "strayfiles-ping": {
      "command": "strayfiles-ping",
      "args": []
    }
  }
}
```

#### Other MCP clients

Any MCP client that supports stdio transport can use this server. The command is:

```
strayfiles-ping
```

### Step 3 (Optional): Unlock remote push (Pro)

```bash
strayfiles-ping auth
```

The pasted token is verified online against your real Strayfiles account
before it is saved locally.

## Usage

Just tell Claude naturally:

- "Run the tests and ping me when done"
- "Deploy to staging, but ping me for approval first"
- "Let me know if the build fails"
- "Notify me when you're finished"

Claude will automatically use the right dialog type:

- **Confirmation**: "Deploy to production?" → Yes/No
- **Choice**: "Which approach?" → Pick from a list
- **Multi-select**: "Which packages to update?" → Check multiple items
- **Text input**: "What should the commit message be?" → Free-form text
- **Secure input**: "Enter the API key" → Masked entry (never logged)
- **Wizard**: "Configure the new service" → Step-by-step questions
- **Notification**: "Build completed!" → Fire-and-forget

## How It Works

1. You ask Claude to do something and ping you
2. Claude runs the task
3. A native macOS dialog appears (or a push notification if you're away)
   If `strayfiles-dialog` is unavailable, Ping uses local queue/poll mode.
4. You respond — choose an option, type text, or snooze for later
5. Claude continues based on your response

## Configuration

```bash
# Set dialog position
strayfiles-ping config set dialog.position center

# Enable dialog sounds
strayfiles-ping config set dialog.sound subtle

# Set timeout (seconds)
strayfiles-ping config set dialog.timeout 300

# View all settings
strayfiles-ping config list
```

Config file: `~/.config/strayfiles-ping/config.toml`

See [docs/config.md](docs/config.md) for the full schema.

## Interaction History

```bash
# View recent interactions
strayfiles-ping history --last 10

# Search by keyword
strayfiles-ping history --search "deploy"

# Filter by project
strayfiles-ping history --project my-app
```

## Troubleshooting

**"Dialog not appearing"**
- Check: `which strayfiles-dialog` (binary must be installed)
- Check: `strayfiles-ping config get dialog.enabled` (must be `true`)

**"strayfiles-ping command not found"**
- Run the install script: `curl -fsSL https://strayfiles.com/ping-install.sh | sh`

**"Authentication failed"** (Pro)
- Run `strayfiles-ping auth` again
- Verify your Strayfiles Pro subscription is active

See [troubleshooting guide](skills/ping/troubleshooting.md) for more.

## Links

- [Architecture](docs/architecture.md)
- [Configuration](docs/config.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
- [License](LICENSE) (MIT)
- [Strayfiles](https://strayfiles.com)
