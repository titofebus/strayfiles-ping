---
name: strayfiles-ping
description: Send notifications to user's phone/desktop when tasks complete and wait for responses. Use when user says "ping me", "notify me", "let me know when done", "text me", "alert me", or asks to be notified about task completion. Also use proactively for long-running tasks (builds, test suites, deployments, large refactors) where user might step away. Requires Strayfiles Pro subscription.
allowed-tools: mcp__strayfiles-ping__ping, mcp__strayfiles-ping__wait_for_response
---

# Strayfiles Ping

Send notifications to the user's iOS/macOS devices and optionally wait for their response. Notifications appear on all connected devices; the first response from any device wins.

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

Send a notification to all user's connected devices.

**Parameters:**
- `message` (string, required): What to tell the user
  - Keep under 200 characters for best mobile display
  - Lock screen shows ~100 characters
- `options` (string[], optional): Quick-reply buttons
  - Maximum 4 options
  - Keep labels short (1-3 words)
  - Example: `["Approve", "Reject", "Skip"]`

**Returns:** Notification ID (use for tracking)

### wait_for_response

Block execution until user responds or timeout expires.

**Parameters:**
- `timeout_seconds` (number, optional): How long to wait
  - Default: 300 (5 minutes)
  - Maximum: 600 (10 minutes)
  - Notifications expire after timeout

**Returns:** User's response text or selected option

## Usage Patterns

### Simple notification (fire and forget)
Use when you just need to inform, no response needed:
```
ping("Build completed successfully! 47 tests passed.")
```

### Get approval before continuing
Use for destructive or important actions:
```
ping("Ready to deploy to production. 23 files changed. Proceed?",
     options=["Deploy", "Cancel", "Show diff"])
response = wait_for_response(timeout_seconds=600)

if response == "Deploy":
    // proceed with deployment
elif response == "Show diff":
    // show the diff, then ask again
else:
    // user cancelled
```

### Notify before long task
Let user know they can step away:
```
ping("Starting full test suite (~10 minutes). I'll ping when done.")
// ... run tests ...
ping("Tests complete: 234 passed, 2 failed. Details above.")
```

### Multiple choice decision
When you need user to pick between options:
```
ping("Found 3 approaches to fix this bug. Which should I implement?",
     options=["Quick fix", "Proper refactor", "Explain options"])
response = wait_for_response()
```

### Waiting for review
After presenting something that needs human review:
```
// ... generate PR description ...
ping("PR description ready above. Want me to create the PR?",
     options=["Create PR", "Edit first", "Cancel"])
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

5. **Set appropriate timeouts**:
   - Quick decisions (yes/no): 5 minutes (default)
   - Code review needed: 10 minutes
   - If user doesn't respond, gracefully handle timeout

6. **Proactive is good**:
   - Ping before starting long tasks (builds, deploys)
   - User appreciates knowing they can step away
   - Better to over-notify than leave user waiting

## Error Handling

If ping fails (auth issue, network, subscription):
- Inform user in chat that ping couldn't be sent
- Continue with the task if possible
- Don't repeatedly retry failed pings

If wait_for_response times out:
- Treat as "no response" not as error
- Ask user in chat what they'd like to do
- Don't block indefinitely

## Requirements

- **Strayfiles Pro subscription** required
- **strayfiles-ping MCP server** must be installed and authenticated
- At least one device (iOS/macOS/TUI) with Ping enabled

See [troubleshooting.md](troubleshooting.md) for setup help.
See [examples.md](examples.md) for more detailed examples.
