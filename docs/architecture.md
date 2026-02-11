# Strayfiles Ping Architecture

## Overview

Strayfiles Ping is an MCP (Model Context Protocol) server that enables AI coding agents to show native dialogs and send push notifications to users, then wait for responses.

## Components

```
┌─────────────────┐
│  Claude Code    │  User's IDE/CLI
│  (AI Agent)     │
└────────┬────────┘
         │ stdin/stdout
         │ (JSON-RPC 2.0)
         ▼
┌─────────────────┐
│  MCP Server     │  Rust binary (strayfiles-ping)
│  (This Project) │
└────────┬────────┘
         │
    ┌────┴────────────────────┐
    │                         │
    ▼ User present            ▼ User away (Pro)
┌─────────────────┐  ┌─────────────────┐
│  Dialog CLI     │  │  Supabase       │
│  (strayfiles-   │  │  ┌──────────┐   │
│   dialog)       │  │  │PostgreSQL│   │
│                 │  │  │   +      │   │
│  Swift binary   │  │  │ Realtime │   │
│  Native macOS   │  │  └──────────┘   │
│  dialogs        │  │  ┌──────────┐   │
└────────┬────────┘  │  │   Edge   │   │
         │           │  │ Functions│   │
         │ JSON      │  └──────────┘   │
         │ stdout    └────────┬────────┘
         │                    │ Push notifications
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│  Native Dialog  │  │  User Devices   │
│  (macOS)        │  │  iOS, macOS, TUI│
└─────────────────┘  └─────────────────┘
```

## Two Binaries

| Binary | Language | Platform | Purpose |
|--------|----------|----------|---------|
| `strayfiles-ping` | Rust | macOS, Linux | MCP server, routing, remote push |
| `strayfiles-dialog` | Swift | macOS only | Native dialog renderer |

Both ship together. The dialog CLI is spawned by the MCP server per dialog and communicates via JSON on stdout.

## Routing Flow

The MCP server decides whether to show a local dialog or send a remote push:

```
1. Are local dialogs enabled? (config: dialog.enabled)
   ├─ No  → Is user Pro?
   │        ├─ Yes → Remote push notification
   │        └─ No  → Error: no way to reach user
   └─ Yes → Is dialog CLI available?
            ├─ No  → Is user Pro?
            │        ├─ Yes → Remote push notification
            │        └─ No  → Error: dialog CLI not found
            └─ Yes → Is user active? (screen unlocked, not idle)
                     ├─ No  → Is user Pro?
                     │        ├─ Yes → Remote push notification
                     │        └─ No  → Local dialog (best effort)
                     └─ Yes → Local dialog
```

Free users always get local dialogs. Pro users get smart routing with remote fallback.

## Data Flow

### 1. Local Dialog (Free + Pro)

```
1. Agent calls: ping("Ready to deploy?", input_type="confirmation")
2. MCP Server:
   - Reads config (~/.config/strayfiles-ping/config.toml)
   - Checks snooze state → returns snooze response if active
   - Checks routing → decides local
   - Spawns: strayfiles-dialog --json '{"message":"Ready to deploy?","input_type":"confirmation"}'
3. Dialog CLI:
   - Reads config (same file)
   - Shows native macOS dialog
   - User responds
   - Writes JSON to stdout, exits
4. MCP Server:
   - Parses JSON response
   - Writes to history
   - Returns to agent
```

### 2. Remote Push (Pro)

```
1. Agent calls: ping("Ready to deploy?")
2. MCP Server:
   - Routing decides remote (user idle/locked)
   - Creates notification via Edge Function
   - Subscribes to Realtime (WebSocket)
3. User responds on device → Supabase
4. Realtime pushes update → MCP Server
5. Response → Agent
```

### 3. Queue Auto-Response

```
1. User pre-adds: strayfiles-ping queue add "approved"
2. Agent calls: ping("Ready?")
3. MCP Server finds queued response → returns immediately
```

## Configuration

Shared config file at `~/.config/strayfiles-ping/config.toml`:

```toml
[dialog]
enabled = true
position = "top-right"
timeout = 600
sound = "none"
always_on_top = true
cooldown = false
cooldown_duration = 1.0

[theme]
accent = ""

[routing]
idle_threshold = 120
prefer = "auto"

[snooze]
until = ""
```

Both binaries read this file. Any application or the CLI can write it.

See [config.md](config.md) for the full schema.

## Dialog CLI Lifecycle

```
Spawn → Read config → Check snooze → Show dialog → Write JSON → Exit
```

- Process spawns fresh per dialog
- No dock icon, no menu bar, no background presence
- Exit code 0 = success (JSON written), exit code 1 = error
- Singleton guard via pid file at /tmp/strayfiles-dialog.pid

## History

Per-day JSON files at `~/.local/share/strayfiles-ping/history/`:

```
history-2025-06-15.json
history-2025-06-16.json
```

- Max 200 entries per day
- Secure input values never logged
- Snoozed auto-returns not recorded
- Queryable via: `strayfiles-ping history [--last N] [--since DATE] [--search TEXT]`

## Key Features

### Atomic Queue Consumption

Single atomic SQL function for queue + notification creation:

```sql
CREATE FUNCTION create_notification_with_queue(...)
RETURNS JSON AS $$
BEGIN
  -- All in one transaction:
  -- 1. Rate limit check
  -- 2. Queue lookup (FOR UPDATE SKIP LOCKED)
  -- 3. Notification creation
  -- 4. Queue marking (with notification_id link)
END;
$$;
```

### Secure Token Storage

Tokens stored in system keychain:
- **macOS**: Keychain Access (native API)
- **Linux**: Secret Service (D-Bus)

### Input Types

Seven input types for structured data collection:

| Type | Description |
|------|-------------|
| `notify` | Fire-and-forget notification |
| `confirmation` | Yes/no dialog |
| `choice` | Single-select with descriptions |
| `multi_select` | Checkbox selection |
| `text` | Free-form text entry |
| `secure_text` | Masked text entry (never logged) |
| `questions` | Multi-question wizard or accordion |

### Snooze & Feedback

- **Snooze**: User defers all dialogs for 1-60 minutes. Global, persisted in config.
- **Feedback**: User redirects the agent with free-form text instead of answering.
- **Comment**: User attaches an optional note alongside their answer.

## Security Model

### Authentication (Pro)

```
1. User: strayfiles-ping auth
2. Browser: https://strayfiles.com/ping/auth
3. Login → Supabase Auth (JWT)
4. Copy token → paste in CLI
5. Keychain: store encrypted
```

### Row Level Security

All database access protected by RLS:

```sql
CREATE POLICY user_notifications ON agent_notifications
  USING (auth.uid() = user_id);
```

## Error Handling

```
PingError
├─ NotAuthenticated (-32001)
├─ NotPro (-32001)
├─ TokenRefreshFailed (-32001)
├─ DialogNotFound (-32002)
├─ DialogDisabled (-32002)
├─ InvalidRequest (-32602)
├─ Timeout (-32002)
├─ RateLimitExceeded (-32003)
├─ ServiceUnavailable (-32004)
└─ Supabase/Http/WebSocket (-32603)
```

## Performance

| Operation | Latency |
|-----------|---------|
| Local dialog spawn to visible | < 50ms |
| Remote ping creation | ~100-300ms |
| Realtime response delivery | ~50-100ms |

## Binary Distribution

```
Platforms:
├─ strayfiles-ping: macOS (arm64, x64), Linux (x64, arm64)
├─ strayfiles-dialog: macOS (universal binary)
└─ Windows: not supported

Distribution:
├─ Supabase Storage (signed binaries via scripts/release.sh)
├─ Install script: curl -fsSL https://strayfiles.com/ping-install.sh | sh
└─ Ed25519 signatures (minisign)
```

## References

- [MCP Specification](https://modelcontextprotocol.io/docs)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Claude Code Plugin API](https://docs.anthropic.com/en/docs/build-with-claude/claude-code)
