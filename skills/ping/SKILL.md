---
name: strayfiles-ping
description: Send notifications to user's phone/desktop when tasks complete and wait for responses. Use when user says "ping me", "notify me", "let me know when done", "text me", "alert me", or asks to be notified about task completion. Also use proactively for long-running tasks (builds, test suites, deployments, large refactors) where user might step away. Requires Strayfiles Pro subscription.
allowed-tools: mcp__strayfiles-ping__ping, mcp__strayfiles-ping__wait_for_response
---

# Strayfiles Ping

Send notifications to the user's iOS/macOS devices and wait for their response.

## CRITICAL: Always Wait for Responses

**By default, `ping()` waits for the user to respond.** This is intentional and correct:
- Just call `ping("your message")` — it will automatically wait up to 5 minutes
- Do NOT set `wait=false` unless you explicitly don't need a response
- The user may be away from their computer — ping is likely your only way to reach them

**Wrong:** `ping("Deploy?", wait=false)` then forgetting to wait → user never gets to respond
**Right:** `ping("Deploy?")` → waits for response → you get "Deploy" or "Cancel"

## When to Use

### Explicit requests
- User says: "ping me", "notify me", "let me know when done"
- User says: "text me", "alert me", "send me a notification"
- User asks: "can you tell me when this is finished?"

### Proactive use (long-running tasks)
- Before starting: builds, full test suites, deployments
- Large refactors affecting many files
- Database migrations or data processing
- Any task that takes more than ~2 minutes

### Getting user input
- Need approval before destructive action (deploy, delete, publish)
- Choice between multiple approaches
- Clarification on ambiguous requirements
- Confirmation before expensive operations

## Available Tools

### ping

Send a notification and wait for the user's response.

**Parameters:**
- `message` (string, required): What to tell the user
  - Keep under 200 characters for best mobile display
  - Lock screen shows ~100 characters
- `options` (string[], optional): Quick-reply buttons
  - Maximum 4 options
  - Keep labels short (1-3 words)
  - Example: `["Approve", "Reject", "Skip"]`
- `wait` (boolean, optional): Whether to wait for response
  - Default: `true` (blocks until response or timeout)
  - Set to `false` for fire-and-forget notifications
- `timeout_seconds` (number, optional): How long to wait
  - Default: 300 (5 minutes)
  - Maximum: 3600 (1 hour)

**Returns:**
- If user responds: `"User responded: \"Deploy\""`
- If timeout: Message explaining user is unavailable with suggestions
- If queue has pre-set response: Returns immediately with the queued response

### wait_for_response (Advanced)

Block execution until user responds to a previous ping.

**Use this only if** you need to do work between sending a ping (with `wait=false`) and waiting for the response. In most cases, just use `ping()` with the default `wait=true`.

**Parameters:**
- `timeout_seconds` (number, optional): How long to wait
  - Default: 300 (5 minutes)
  - Maximum: 3600 (1 hour)

## Usage Patterns

### Get approval before continuing (most common)
```
response = ping("Ready to deploy to production. 23 files changed. Proceed?",
                options=["Deploy", "Cancel", "Show diff"])

if response contains "Deploy":
    // proceed with deployment
elif response contains "Show diff":
    // show the diff, then ask again
else:
    // user cancelled or timed out
```

### Simple notification (fire and forget)
Use when you just need to inform, no response needed:
```
ping("Build completed successfully! 47 tests passed.", wait=false)
```

### Notify before long task
Let user know they can step away:
```
ping("Starting full test suite (~10 minutes). I'll ping when done.", wait=false)
// ... run tests ...
response = ping("Tests complete: 234 passed, 2 failed. Want details?",
                options=["Show failures", "Continue", "Stop"])
```

### Multiple choice decision
When you need user to pick between options:
```
response = ping("Found 3 approaches to fix this bug. Which should I implement?",
                options=["Quick fix", "Proper refactor", "Explain options"])
```

### Waiting for review
After presenting something that needs human review:
```
// ... generate PR description ...
response = ping("PR description ready above. Want me to create the PR?",
                options=["Create PR", "Edit first", "Cancel"])
```

### Advanced: Do work while waiting
If you need to do something between sending and waiting:
```
ping("Starting deployment...", wait=false)
// ... do some setup work ...
response = wait_for_response(timeout_seconds=600)
```

## Queue for Instant Responses

Users can pre-add responses to a queue. When you call `ping()`, if the queue has items, it returns immediately with the queued response instead of waiting.

This is useful for:
- **Automated workflows**: Pre-set "Deploy" responses for CI/CD
- **AI tools that can't wait**: Codex, Cursor, etc. may not support long MCP waits

```bash
# User adds to queue before running AI
strayfiles-ping queue add "Deploy"
strayfiles-ping queue add "Yes"

# AI calls ping() and gets instant response from queue
response = ping("Ready to deploy?")  # Returns immediately: "Deploy"
```

## Best Practices

1. **Be concise**: Mobile lock screens truncate at ~100 characters
   - Bad: "The build process has completed and all tests have passed successfully"
   - Good: "Build done. 47 tests passed."

2. **Include actionable context**:
   - Bad: "Build failed"
   - Good: "Build failed: missing import in auth.rs:42"

3. **Use options for discrete choices**:
   - When you need yes/no, A/B/C, or approve/reject
   - Don't use for open-ended questions (let user type)

4. **Don't over-ping**:
   - One ping per logical milestone
   - Don't ping for each file changed
   - Batch related updates into one message

5. **Handle timeouts gracefully**:
   - If user doesn't respond, the message will guide you
   - Consider continuing with a safe default
   - Or leave a summary for the user to review later

6. **Proactive is good**:
   - Ping before starting long tasks (builds, deploys)
   - User appreciates knowing they can step away
   - Better to over-notify than leave user waiting

7. **One pending ping at a time**:
   - Wait for response before sending another ping
   - Multiple pings will overwrite each other

## Error Handling

If ping fails (auth issue, network, subscription):
- Inform user in chat that ping couldn't be sent
- Continue with the task if possible
- Don't repeatedly retry failed pings

If ping times out (user didn't respond):
- The response message includes guidance
- Treat as "no response" not as error
- Continue with safe defaults or leave a summary

## Requirements

- **Strayfiles Pro subscription** required
- **strayfiles-ping MCP server** must be installed and authenticated
- At least one device (iOS/macOS/TUI) with Ping enabled

See [troubleshooting.md](troubleshooting.md) for setup help.
See [examples.md](examples.md) for more detailed examples.
