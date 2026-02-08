# Ping Troubleshooting

Common issues and solutions for Strayfiles Ping.

## Setup Issues

### "MCP server not found"

The `strayfiles-ping` binary isn't installed or not in PATH.

**Solution:**
```bash
# Install
curl -fsSL https://strayfiles.com/ping-install.sh | sh

# Verify installation
which strayfiles-ping
strayfiles-ping --version
```

### MCP server not in Claude Code

Claude doesn't see the ping tools.

**Solution:**
```bash
# Add MCP server to Claude Code
claude mcp add strayfiles-ping -- strayfiles-ping

# Or manually edit ~/.claude/mcp.json:
{
  "mcpServers": {
    "strayfiles-ping": {
      "command": "strayfiles-ping"
    }
  }
}

# Restart Claude Code (exit and reopen)
# /mcp to verify the server is loaded
```

## Native Dialog Issues

### Dialog not appearing

The `strayfiles-dialog` binary may be missing or local dialogs disabled.

**Check:**
```bash
# Verify dialog binary is installed
which strayfiles-dialog
strayfiles-dialog --version

# Check if local dialogs are enabled
strayfiles-ping config get dialog.enabled
# Should be "true"

# Re-enable if disabled
strayfiles-ping config set dialog.enabled true
```

### Dialog appears in wrong position

**Solution:**
```bash
# Set dialog position (options: top-right, center, top-left, bottom-right)
strayfiles-ping config set dialog.position top-right
```

### Dialog disappears too quickly

The timeout may be too short.

**Solution:**
```bash
# Set timeout in seconds (1-3600)
strayfiles-ping config set dialog.timeout 600
```

### Dialog sound not playing

Sound is silent by default.

**Solution:**
```bash
# Enable dialog sound (options: none, subtle, pop, chime)
strayfiles-ping config set dialog.sound subtle
```

### "Another dialog is already active"

Only one dialog can be shown at a time. This error means a previous dialog is still open.

**Solution:**
- Respond to or dismiss the existing dialog
- If the dialog is stuck: `kill $(cat /tmp/strayfiles-dialog.pid)`

### Button cooldown feels too long

Button cooldown prevents accidental input but may feel sluggish.

**Solution:**
```bash
# Disable cooldown entirely
strayfiles-ping config set dialog.cooldown false

# Or adjust duration (0.1 to 3.0 seconds)
strayfiles-ping config set dialog.cooldown_duration 0.5
```

### Snooze seems stuck

If pings keep returning snooze responses after the snooze should have expired.

**Check:**
```bash
# View current snooze state
strayfiles-ping config get snooze.until

# Clear snooze manually
strayfiles-ping config set snooze.until ""
```

## Remote Push Issues (Pro)

### "Not authenticated"

The MCP server doesn't have valid credentials for remote push.

**Solution:**
```bash
# Run authentication flow
strayfiles-ping auth
```

### "Subscription required"

Remote push notifications require a Pro subscription.

**Solution:**
1. Open Strayfiles app (iOS, macOS, or TUI)
2. Go to Settings > Account
3. Upgrade to Pro subscription
4. Re-authenticate: `strayfiles-ping auth`

**Note:** Local native dialogs work without a subscription.

### Remote notifications not appearing on device

**Check:**
1. **System notifications allowed?**
   - iOS: Settings > Strayfiles > Notifications > Allow
   - macOS: System Settings > Notifications > Strayfiles > Allow
2. **Device connected to internet?**
3. **Authenticated on device?** Must be logged into same account
4. **Ping enabled in app?** Settings > Ping > Enable

### Notifications delayed

Realtime subscription may have dropped.

**Solution:**
- iOS/macOS: Force quit and reopen app
- TUI: Press `r` to reconnect, or restart
- Check: Settings > Ping shows "Connected" status

## Non-macOS

### "Native dialogs are only available on macOS"

The dialog CLI only runs on macOS. On Linux/Windows, remote push is the only option.

**Solution:**
```bash
# Set up remote push notifications (requires Pro)
strayfiles-ping auth
```

## Response Issues

### Response not received by Claude

**Check:**
1. Did you respond before timeout?
2. Claude still waiting? (check terminal)

**If Claude moved on:**
- Tell Claude your answer in chat: "My response to the ping was: Deploy"

### Notification expired before I could respond

**Solution:**
- Ask Claude to use longer timeout: "ping me and wait up to 10 minutes"
- Respond sooner when you see the dialog

## Configuration

### View all settings

```bash
strayfiles-ping config list
```

### Reset to defaults

```bash
strayfiles-ping config reset
```

### Config file location

```
~/.config/strayfiles-ping/config.toml
```

## History

### View recent interactions

```bash
strayfiles-ping history --last 10
```

### Search history

```bash
strayfiles-ping history --search "deploy"
strayfiles-ping history --project my-app
```

### Clear history

```bash
strayfiles-ping history clear
```

## Debug Mode

For detailed logging:

```bash
# Run MCP server with debug output
RUST_LOG=debug strayfiles-ping

# Or set in Claude Code config
{
  "mcpServers": {
    "strayfiles-ping": {
      "command": "strayfiles-ping",
      "env": {
        "RUST_LOG": "debug"
      }
    }
  }
}
```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `dialog_not_found` | Dialog binary missing | Reinstall: `curl -fsSL https://strayfiles.com/ping-install.sh \| sh` |
| `dialog_disabled` | Local dialogs off, no Pro | `strayfiles-ping config set dialog.enabled true` |
| `auth_required` | Not logged in (remote) | `strayfiles-ping auth` |
| `subscription_required` | No Pro (remote only) | Upgrade in app or enable local dialogs |
| `token_expired` | Auth token old | `strayfiles-ping auth` |
| `notification_expired` | Timeout reached | Respond faster or increase timeout |
| `another_dialog_active` | Dialog already showing | Dismiss existing dialog |

## Getting Help

1. **Check logs:** MCP server stderr in Claude Code terminal
2. **Report bug:** GitHub Issues at github.com/titofebus/strayfiles-ping
