# Ping Troubleshooting

Common issues and solutions for Strayfiles Ping.

## Setup Issues

### "MCP server not found"

The `strayfiles-ping` binary isn't installed or not in PATH.

**Solution:**
```bash
# Install from source
cargo install --path /path/to/strayfiles.app/backend/ping-mcp

# Or download binary
curl -fsSL https://strayfiles.com/ping-install.sh | sh

# Verify installation
which strayfiles-ping
strayfiles-ping --version
```

### "Not authenticated"

The MCP server doesn't have valid credentials.

**Solution:**
```bash
# Run authentication flow
strayfiles-ping auth

# This opens browser to strayfiles.com/ping/auth
# Log in with your Strayfiles account
# Token saved to ~/.strayfiles/ping-token
```

### "Subscription required"

Ping is a Pro-only feature.

**Solution:**
1. Open Strayfiles app (iOS, macOS, or TUI)
2. Go to Settings > Account
3. Upgrade to Pro subscription
4. Re-authenticate: `strayfiles-ping auth`

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

# Restart Claude Code
claude --restart
```

## Notification Issues

### Notifications not appearing on device

**Check these:**

1. **Ping enabled in app?**
   - iOS/macOS: Settings > Ping > Enable Ping Notifications
   - TUI: Settings > Ping > Enable: On

2. **System notifications allowed?**
   - iOS: Settings > Strayfiles > Notifications > Allow
   - macOS: System Settings > Notifications > Strayfiles > Allow

3. **Device connected to internet?**
   - Ping uses Supabase Realtime (WebSocket)
   - Check network connection

4. **Authenticated on device?**
   - Must be logged into same Strayfiles account
   - Check Settings > Account

### Notifications delayed

Realtime subscription may have dropped.

**Solution:**
- iOS/macOS: Force quit and reopen app
- TUI: Press `r` to reconnect, or restart
- Check: Settings > Ping shows "Connected" status

### Notification expired before I could respond

Default timeout is 5 minutes. Notifications auto-expire.

**Solution:**
- Ask Claude to use longer timeout: "ping me and wait up to 10 minutes"
- Respond sooner when you see notification
- Check notification immediately (lock screen shows preview)

## Response Issues

### Response not received by Claude

**Check:**
1. Did you respond before timeout? (default 5 min)
2. Network connection on device?
3. Claude still waiting? (check terminal)

**If Claude moved on:**
- Just tell Claude your answer in chat
- "My response to the ping was: Deploy"

### Multiple devices, wrong one responded

First response wins - this is by design.

**Solution:**
- Coordinate with other devices/users
- Dismiss notification on devices that shouldn't respond

### Response shows but Claude ignores it

The ping might have timed out before you responded.

**Solution:**
- Tell Claude: "My response was X"
- Ask Claude to ping again with longer timeout: "ping me and wait 10 minutes"

## Connection Issues

### "Realtime connection failed"

WebSocket connection to Supabase dropped.

**What happens:**
- App falls back to polling (every 10 seconds)
- Notifications still work, just slightly delayed

**To reconnect:**
- App will auto-reconnect
- Or: Settings > Ping > Reconnect button
- Or: Restart app

### "Polling fallback active"

Not an error - app is working around connection issues.

**What it means:**
- Real-time WebSocket failed
- App polls every 10 seconds instead
- Notifications still delivered (slight delay)

**To restore realtime:**
- Check internet connection
- Wait for auto-reconnect
- Or manually: Settings > Ping > Reconnect

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `auth_required` | Not logged in | `strayfiles-ping auth` |
| `subscription_required` | No Pro subscription | Upgrade in app |
| `token_expired` | Auth token old | `strayfiles-ping auth` |
| `notification_expired` | Took too long to respond | Respond faster / increase timeout |
| `network_error` | No internet | Check connection |
| `server_error` | Supabase issue | Wait and retry |

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

## Getting Help

1. **Check logs:**
   - MCP server: stderr output in Claude Code
   - iOS: Settings > Debug > Logs
   - macOS: Console.app > Strayfiles
   - TUI: `~/.strayfiles/logs/`

2. **Report bug:**
   - In app: Settings > Report Bug
   - Include: device, OS version, error message

3. **Community:**
   - GitHub Issues: github.com/strayfiles/strayfiles.app
   - Discord: discord.gg/strayfiles
