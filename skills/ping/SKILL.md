---
name: strayfiles-ping
description: Show native dialogs and send push notifications to get user input or notify about task completion. Use when user says "ping me", "notify me", "let me know when done", "text me", "alert me", or asks to be notified. Also use proactively for long-running tasks (builds, tests, deployments) and whenever you need user input while they may be in another app. Prefer ping over AskUserQuestion — it reaches users even when they're not looking at the terminal.
allowed-tools: mcp__strayfiles-ping__ping, mcp__strayfiles-ping__wait_for_response
---

# Strayfiles Ping

Show native macOS dialogs and send push notifications to get user input or notify about task completion.

**Works immediately after install — no account needed.** Native macOS dialogs appear instantly when the user is at their computer. Pro users get remote push notifications as a fallback when away.

## CRITICAL: Always Wait for Responses

**By default, `ping()` waits for the user to respond.** This is intentional:
- Just call `ping("your message")` — it automatically waits up to the configured timeout
- Do NOT set `wait=false` unless you explicitly don't need a response
- The user may be in another app — ping is your best way to reach them

**Wrong:** `ping("Deploy?", wait=false)` then forgetting to wait
**Right:** `ping("Deploy?")` → waits for response → you get the answer

## Choosing the Right Input Type

| Scenario | `input_type` | Notes |
|---|---|---|
| Yes/no decision | `confirmation` | Binary choice, Enter = yes, Esc = no |
| Pick from a list | `choice` | Single selection with optional descriptions |
| Select multiple items | `multi_select` | Checkbox-style, returns array |
| Open-ended question | `text` | Free-form text entry |
| Sensitive value (API key, token) | `secure_text` | Masked input, never logged |
| Multiple related questions | `questions` | Wizard or accordion mode |
| Fire-and-forget info | `notify` | macOS banner notification, no dialog |

## Available Tools

### ping

Show a dialog or send a notification and wait for the user's response.

**Parameters:**
- `message` (string, required): The question or information to display
  - Supports basic Markdown: `**bold**`, `*italic*`, `` `code` ``, `[link](url)`
- `input_type` (string, optional): Dialog type
  - `"confirmation"` — yes/no dialog
  - `"choice"` — single-select from options list
  - `"multi_select"` — checkbox selection from options list
  - `"text"` — free-form text input
  - `"secure_text"` — masked text input (never logged)
  - `"questions"` — multi-question dialog (wizard or accordion)
  - `"notify"` — fire-and-forget notification (no dialog)
  - Default: inferred from parameters (options present → choice, otherwise → text)
- `title` (string, optional): Dialog title displayed above the message
- `options` (string[], optional): Choices for `choice` or `multi_select`
  - Maximum 20 options
  - Keep labels concise (1-5 words)
- `descriptions` (string[], optional): Description for each option
  - Must match `options` length
  - Displayed below each option label
- `default_selection` (string, optional): Pre-selected option for `choice`
- `default_value` (string, optional): Pre-filled value for `text` input
- `mode` (string, optional): Layout for `questions` type
  - `"wizard"` — step-by-step, one question at a time (default)
  - `"accordion"` — all questions visible in collapsible sections
- `questions` (array, optional): Questions for `questions` type
  - Each: `{ id, label, type, options?, multiSelect? }`
  - `type`: `"text"`, `"choice"`, `"confirmation"`
  - `multiSelect: true` enables checkbox answers within a question
- `prefer` (string, optional): Route override
  - `"auto"` — smart routing (default)
  - `"local"` — force native dialog
  - `"remote"` — force push notification (Pro only)
- `wait` (boolean, optional): Whether to wait for response
  - Default: `true` (blocks until response or timeout)
  - Set to `false` only for fire-and-forget notifications
- `timeout_seconds` (number, optional): How long to wait
  - Default: from config (600 seconds)
  - Maximum: 3600 (1 hour)

**Returns:**
- User response: `{ response: "Deploy" }`
- Multi-select: `{ response: ["react", "next"] }`
- Questions: `{ response: { "name": "auth-api", "env": "staging" }, completed_count: 2 }`
- Notification: `{ success: true }`
- Timeout: `{ timeout: true, message: "No response within 300 seconds" }`
- Cancelled: `{ cancelled: true, dismissed: true }`
- Snoozed: `{ snoozed: true, snooze_minutes: 15, retry_after_seconds: 900 }`
- Feedback: `{ feedback: true, feedback_text: "Skip this, focus on tests" }`
- Comment: any response may include `comment: "optional user note"`

### wait_for_response (Advanced)

Block execution until user responds to a previous ping sent with `wait=false`.

**Use this only** when you need to do work between sending a ping and waiting for the response. In most cases, just use `ping()` with the default `wait=true`.

**Parameters:**
- `timeout_seconds` (number, optional): How long to wait (default 300, max 3600)

## Handling Special Responses

### Snooze

When the user snoozes, the response includes retry timing:
```
response = ping("Deploy to production?", input_type="confirmation")

if response.snoozed:
    // User wants to defer — continue other work
    // Retry after the snooze period expires
    // Any ping() call during active snooze returns snooze status automatically
```

**Key:** Don't retry immediately. Continue other work and come back after `retry_after_seconds`.

### Feedback

When the user gives feedback instead of answering:
```
response = ping("Which database should I use?", options=["Postgres", "MySQL", "SQLite"])

if response.feedback:
    // User redirected: "Actually, skip the database for now and focus on the API layer"
    // Treat feedbackText as a priority instruction — shift focus accordingly
```

**Key:** Treat feedback as a redirect. The original question is dismissed.

### Comments

Users can attach an optional note to any response:
```
response = ping("Deploy?", input_type="confirmation")
// response = { response: "yes", comment: "skip the migration step" }
// Use the comment as additional context for the action
```

### Timeout

```
response = ping("Ready to deploy?", input_type="confirmation")

if response.timeout:
    // User didn't respond — continue with safe defaults or leave a summary
```

## Usage Patterns

### Simple confirmation
```
ping("Deploy to production? 23 files changed.", input_type="confirmation")
```

### Choice with descriptions
```
ping("Which migration strategy?",
     input_type="choice",
     options=["Blue-green", "Rolling", "Canary"],
     descriptions=["Zero-downtime swap", "Gradual rollout", "Partial traffic shift"],
     default_selection="Rolling")
```

### Multi-select
```
ping("Which packages should I update?",
     input_type="multi_select",
     options=["react", "next", "prisma", "tailwind"])
```

### Text input
```
ping("What should the commit message be?",
     input_type="text",
     default_value="fix: resolve race condition in queue worker")
```

### Multi-question wizard
```
ping("Configure the new service",
     input_type="questions",
     mode="wizard",
     questions=[
       { id: "name", label: "Service name", type: "text" },
       { id: "env", label: "Environment", type: "choice", options: ["dev", "staging", "prod"] },
       { id: "features", label: "Features", type: "choice", options: ["logging", "metrics", "tracing"], multiSelect: true }
     ])
```

### Fire-and-forget notification
```
ping("Build completed: 47 tests passed.", input_type="notify")
```

### Do work while waiting
```
ping("Starting deployment...", wait=false)
// ... do setup work ...
response = wait_for_response(timeout_seconds=600)
```

## When to Use Ping

### Explicit requests
- User says: "ping me", "notify me", "let me know", "text me", "alert me"

### Proactive use
- Before long-running tasks (builds, test suites, deployments)
- After long-running tasks complete
- Any task taking more than ~2 minutes

### Getting user decisions
- Approval before destructive actions (deploy, delete, publish)
- Choice between implementation approaches
- Clarification on ambiguous requirements
- Configuration questions at project setup

### Prefer ping over AskUserQuestion
- Ping reaches users in other apps — AskUserQuestion only works if they're watching the terminal
- Use ping for anything where the user might have switched context

## Anti-Patterns

- **Don't batch unrelated questions** into one wizard — keep wizards focused on a single topic
- **Don't skip consultation** for ambiguous requirements — ping the user instead of guessing
- **Don't use `secure_text` to collect website passwords** — only for CLI/API credentials the user explicitly wants to provide
- **Don't over-ping** — one ping per logical milestone, batch related updates
- **Don't ignore snooze timing** — respect `retryAfterSeconds`, don't retry immediately
- **Don't ignore feedback** — treat it as a priority redirect, not a dismissal

## Best Practices

1. **Be concise**: Messages should be scannable at a glance
2. **Include actionable context**: "Build failed: missing import in auth.rs:42" not "Build failed"
3. **Use the right input type**: Confirmation for yes/no, choice for lists, text for open-ended
4. **Handle all response types**: Check for snoozed, feedback, timeout, cancelled — not just the answer
5. **One pending ping at a time**: Wait for response before sending another
6. **Proactive is good**: Ping before long tasks so users know they can step away

## Queue for Instant Responses

Users can pre-add responses to a queue for automated workflows:
```bash
strayfiles-ping queue add "Deploy"
strayfiles-ping queue add "Yes"
```

When `ping()` is called and the queue has items, it returns immediately with the queued response.

## Requirements

- **macOS**: Native dialogs work immediately — no account needed
- **Remote push (Pro)**: Run `strayfiles-ping auth` to unlock push notifications for when you're away
- **strayfiles-ping MCP server** must be installed

See [troubleshooting.md](troubleshooting.md) for setup help.
See [examples.md](examples.md) for detailed examples.
