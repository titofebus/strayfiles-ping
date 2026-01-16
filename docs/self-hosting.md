# Self-Hosting Strayfiles Ping

This guide explains how to self-host the strayfiles-ping plugin, including the MCP server and Edge Functions.

## Overview

Strayfiles Ping consists of:

1. **MCP Server** (Rust binary) - Runs on developer's machine
2. **Edge Functions** (Deno/TypeScript) - Runs on Supabase
3. **Database** (PostgreSQL) - Supabase managed or self-hosted
4. **Realtime** (WebSocket) - Supabase Realtime for instant responses

## Prerequisites

- Supabase account (free tier works)
- Rust toolchain (stable)
- Supabase CLI
- PostgreSQL knowledge (for migrations)

## Setup Steps

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Note your project URL and API keys

### 2. Run Database Migrations

Apply migrations in order from `backend/development/`:

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login
supabase login

# Link your project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push
```

**Required migrations for Ping:**
- `023_agent_notifications_history_and_queue.sql` - Core tables
- `024_agent_notification_subscriptions.sql` - Pro tier checks
- `027_user_consents.sql` - User consent tracking
- `028_fix_queue_transaction.sql` - Queue transaction fix
- `029_queue_size_limit.sql` - Queue size enforcement

### 3. Configure Edge Function Secrets

Set secrets in Supabase Dashboard → Edge Functions → Secrets:

```bash
# Required Secrets
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
STRAYFILES_OTP_PEPPER=<generate-with-openssl-rand-base64-32>

# Optional (for full functionality)
RESEND_API_KEY=re_xxxxxxxxxxxx
EMAIL_FROM=noreply@yourdomain.com
BUG_REPORT_EMAIL=support@yourdomain.com

# Stripe (if using Pro subscriptions)
STRIPE_SECRET_KEY=sk_xxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
STRAYFILES_PRO_PRICE_ID=price_xxxxxxxxxxxx
```

### 4. Deploy Edge Functions

Deploy from `backend/development/functions/`:

```bash
cd backend/development

# Create Supabase functions directory
mkdir -p supabase/functions

# Copy function
cp -r functions/create-agent-notification supabase/functions/

# Deploy
supabase functions deploy create-agent-notification --project-ref your-project-ref

# Cleanup
rm -rf supabase
```

**Required functions:**
- `create-agent-notification` - Creates notifications with queue support
- `cleanup-expired` - Cleans up expired notifications (optional)

### 5. Build MCP Server Binary

```bash
cd plugins/strayfiles-ping/server

# Set environment variables for compilation
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"

# Build release binary
cargo build --release

# Binary location
ls -lh target/release/strayfiles-ping
```

### 6. Install Plugin

```bash
# Install from local directory
claude plugin install /path/to/strayfiles-ping

# Or publish to GitHub and install
claude plugin install https://github.com/yourusername/strayfiles-ping.git
```

## Configuration

### Environment Variables

The MCP server needs these values **embedded at compile time**:

- `SUPABASE_URL` - Your Supabase project URL (public)
- `SUPABASE_ANON_KEY` - Your anon/public key (public, RLS-protected)

End users don't need any `.env` file - these are baked into the binary.

### Database Schema

**Tables used by Ping:**

| Table | Purpose |
|-------|---------|
| `agent_notifications` | User notifications |
| `agent_notification_queue` | Pre-programmed responses |
| `user_subscriptions` | Pro tier tracking |
| `user_consents` | Feature consent tracking |

### RLS Policies

Ensure Row Level Security is enabled:

```sql
-- Users can only access their own notifications
CREATE POLICY "Users can view own notifications"
  ON agent_notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications"
  ON agent_notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## Testing

### Test Authentication

```bash
strayfiles-ping auth
# Follow prompts to authenticate
```

### Test Notification

```bash
# Run test command
strayfiles-ping test "Test notification"
```

### Check Queue

```bash
# Add queue item
strayfiles-ping queue add "auto-response"

# List queue
strayfiles-ping queue list

# Remove queue item
strayfiles-ping queue remove <id>
```

## Monitoring

### Database Queries

Check notification activity:

```sql
-- Recent notifications
SELECT * FROM agent_notifications
ORDER BY created_at DESC
LIMIT 10;

-- Queue usage
SELECT user_id, COUNT(*) as queue_size
FROM agent_notification_queue
WHERE used_at IS NULL
GROUP BY user_id;

-- Auto-response rate limiting
SELECT user_id, COUNT(*) as responses_last_hour
FROM agent_notifications
WHERE status = 'responded'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id;
```

### Logs

Check Edge Function logs in Supabase Dashboard:

```
Dashboard → Edge Functions → create-agent-notification → Logs
```

## Troubleshooting

### Authentication Issues

**Problem:** "Not authenticated" error

**Solution:**
1. Run `strayfiles-ping auth` to re-authenticate
2. Check token storage: `strayfiles-ping status`
3. Verify Supabase project URL and keys

### Queue Not Working

**Problem:** Auto-responses not triggered

**Solution:**
1. Check queue items exist: `strayfiles-ping queue list`
2. Verify rate limit not exceeded (10/hour)
3. Check Edge Function logs for errors
4. Ensure `028_fix_queue_transaction.sql` migration applied

### Connection Issues

**Problem:** "Service unavailable" error

**Solution:**
1. Check Supabase project status
2. Verify SUPABASE_URL in binary
3. Test Edge Function directly:
   ```bash
   curl -X POST https://your-project.supabase.co/functions/v1/create-agent-notification \
     -H "Authorization: Bearer your-token" \
     -H "Content-Type: application/json" \
     -d '{"message":"test"}'
   ```

## Security Considerations

### Token Storage

Tokens are stored in system keychain:
- **macOS**: Keychain Access.app
- **Linux**: Secret Service (GNOME Keyring, KWallet)

No plaintext tokens on disk (after migration).

### Database Security

- Use Row Level Security (RLS) for all tables
- Never expose service role key to clients
- Rotate secrets regularly
- Monitor for unusual activity

### Rate Limiting

Built-in limits:
- 10 auto-responses per hour per user
- 100 queue items per user
- Notification expiration: 10 minutes

## Updating

### Update Database Schema

```bash
# Pull latest migrations
git pull

# Apply new migrations
supabase db push
```

### Update Edge Functions

```bash
# Redeploy updated function
supabase functions deploy create-agent-notification --project-ref your-project-ref
```

### Update MCP Server

```bash
# Pull latest code
git pull

# Rebuild binary
cargo build --release

# Users reinstall plugin
claude plugin update strayfiles-ping
```

## Cost Estimation

**Supabase Free Tier:**
- Database: 500 MB included
- Edge Functions: 500K requests/month
- Realtime: Unlimited connections
- **Cost:** $0/month for moderate usage

**Paid Tier (Pro):**
- For production or heavy usage
- **Cost:** $25/month base + usage

## Support

- Documentation: https://strayfiles.com/docs/pro/ping
- Issues: https://github.com/titofebus/strayfiles-ping/issues
- Email: support@strayfiles.com

## License

Self-hosted deployments are covered under the MIT License. See LICENSE file for details.
