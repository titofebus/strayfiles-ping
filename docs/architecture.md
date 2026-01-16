# Strayfiles Ping Architecture

## Overview

Strayfiles Ping is an MCP (Model Context Protocol) server that enables AI coding agents to send notifications to users and wait for responses.

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
         │ HTTPS + WebSocket
         │
         ▼
┌─────────────────┐
│  Supabase       │  Backend infrastructure
│  ┌──────────┐   │
│  │PostgreSQL│   │  - Notifications table
│  │   +      │   │  - Queue table
│  │ Realtime │   │  - User subscriptions
│  └──────────┘   │
│  ┌──────────┐   │
│  │   Edge   │   │  - create-agent-notification
│  │ Functions│   │  - cleanup-expired
│  └──────────┘   │
└────────┬────────┘
         │ Push notifications
         ▼
┌─────────────────┐
│  User Devices   │  iOS, macOS, Web
│  (Strayfiles)   │  Receive pings
└─────────────────┘
```

## Data Flow

### 1. Sending a Ping

```
1. Agent calls: ping("Ready to deploy?")
2. MCP Server → Edge Function: create_notification()
3. Edge Function:
   - Checks for queued response
   - If queue item exists: auto-respond
   - Else: create pending notification
4. Response → Agent: notification_id + status
```

### 2. Waiting for Response

By default, `ping()` waits for a response automatically. The flow is:

```
1. Agent calls: ping("Ready to deploy?")
2. MCP Server:
   - Creates notification
   - Subscribes to Realtime (WebSocket)
   - Listens for notification updates
3. User responds on device → Supabase
4. Realtime pushes update → MCP Server
5. Response → Agent: user's answer
```

For advanced use cases, agents can use `wait=false` and call `wait_for_response()` separately.

### 3. Queue Auto-Response

```
1. User pre-adds: queue add "approved"
2. Agent calls: ping("Ready?")
3. Edge Function:
   - Finds queued response: "approved"
   - Auto-responds immediately
   - Marks queue item as used
4. Response → Agent: instant "approved"
```

## Key Features

### Atomic Queue Consumption

**Problem:** Queue items were marked as "used" before notification creation, causing data loss on network failures.

**Solution:** Single atomic SQL function:

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

Automatic migration from file → keychain on first use.

### Rate Limiting

```
10 auto-responses per hour
├─ Enforced at SQL function level
├─ Counted per user_id
└─ Returns 429 on exceeded
```

### Protocol Compliance

MCP 2025-11-25:
- `protocolVersion`: "2025-11-25"
- `isError: false` on successful tool results
- `listChanged: false` capability
- JSON-RPC 2.0 validation

## Security Model

### Authentication

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
-- Users can only see their own notifications
CREATE POLICY user_notifications ON agent_notifications
  USING (auth.uid() = user_id);
```

### Pro Tier Enforcement

```
1. Check user_subscriptions table
2. If tier != 'pro': return NotPro error
3. Else: allow operation
```

## Error Handling

### Error Hierarchy

```
PingError
├─ NotAuthenticated (-32001)
├─ NotPro (-32001)
├─ TokenRefreshFailed (-32001)
├─ InvalidToken (-32602)
├─ InvalidRequest (-32602)
├─ Timeout (-32002)
├─ RateLimitExceeded (-32003)
├─ QueueLimitExceeded (-32003)
├─ ServiceUnavailable (-32004)
└─ Supabase/Http/WebSocket (-32603)
```

### Retry Strategy

- Token refresh: Automatic with backoff
- WebSocket reconnect: Exponential backoff
- HTTP requests: No retry (fail fast)

## Performance

### Latency

- Local operation: < 1ms
- Ping creation: ~100-300ms (HTTPS + DB)
- Realtime response: ~50-100ms (WebSocket)

### Scalability

- Supabase Free: 500K requests/month
- Realtime: Unlimited concurrent connections
- Queue size: 100 items/user

## Testing

### Unit Tests

```rust
#[test]
fn test_token_expiration() { ... }

#[test]
fn test_message_validation() { ... }
```

### Integration Tests

```rust
#[tokio::test]
async fn test_ping_with_queue() {
    let mock_server = MockSupabase::start().await;
    // Test full flow
}
```

### Test Command

```bash
strayfiles-ping test "Test message"
```

## Deployment

### Binary Distribution

```
Platforms:
├─ macOS (arm64, x64)
├─ Linux (x64, arm64)
└─ Windows (planned)

Distribution:
├─ GitHub Releases (signed binaries)
├─ Homebrew (planned)
└─ Install script: curl | sh
```

### Edge Functions

```
Deployment:
├─ Supabase CLI
├─ CI/CD (GitHub Actions)
└─ Manual dashboard upload
```

## Monitoring

### Metrics

- Notifications created
- Auto-responses triggered
- Rate limits hit
- Errors by type

### Logging

```rust
// Production (info level)
info!("Sending ping ({} chars)", msg.len());

// Debug (debug level)
debug!("Ping content: {}", msg);
```

## Future Enhancements

### Planned

- Windows support
- OAuth device flow (replace manual token paste)
- Offline queue (store pings locally when offline)
- Binary signature verification
- CI/CD integration testing

### Not Planned

- Multi-user collaboration (see Teams feature in main app)
- Custom notification sounds (device-level feature)
- Third-party integrations (keep focused on Claude Code)

## References

- [MCP Specification](https://modelcontextprotocol.io/docs)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Claude Code Plugin API](https://docs.anthropic.com/en/docs/build-with-claude/claude-code)
