# Ping Examples

Detailed examples of using Strayfiles Ping in real scenarios.

**Note:** By default, `ping()` waits for the user to respond. You don't need to call `wait_for_response()` separately unless you want to do work between sending and waiting.

## Confirmation Dialogs

### Deploy approval

```
User: "Deploy to production"

Claude:
// After preparing deployment...
response = ping("Deploy to production? 23 files changed, 4 migrations pending.",
                input_type="confirmation")

if response.response == "yes":
    // Proceed with deployment
    // Check for comment like "skip migration step"
elif response.snoozed:
    // Continue other work, retry after retry_after_seconds
elif response.feedback:
    // User redirected — follow feedbackText instructions
```

### Destructive operation

```
User: "Clean up old branches"

Claude:
response = ping("Delete 47 stale branches (>90 days old)?",
                input_type="confirmation")

if response.response == "yes":
    // Delete branches
    ping("Deleted 47 branches. Main and develop preserved.", input_type="notify")
```

## Choice Dialogs

### Implementation approach

```
User: "Fix the performance issue in search"

Claude:
response = ping("Which approach for search performance?",
                input_type="choice",
                options=["Add index", "Caching layer", "Rewrite algorithm"],
                descriptions=["+15% speed, quick", "+60% speed, moderate effort", "+200% speed, complex"])
```

### Migration strategy

```
response = ping("Which migration strategy?",
                input_type="choice",
                options=["Blue-green", "Rolling", "Canary", "Big bang"],
                descriptions=["Zero-downtime swap", "Gradual rollout", "Partial traffic", "All at once"],
                default_selection="Rolling")
```

## Multi-Select Dialogs

### Package updates

```
response = ping("Which packages should I update?",
                input_type="multi_select",
                options=["react@19", "next@15", "prisma@6", "tailwind@4"])

// response.response = ["react@19", "next@15"]
```

### Feature selection

```
response = ping("Which features to enable for the new service?",
                input_type="multi_select",
                options=["logging", "metrics", "tracing", "rate-limiting", "caching"])
```

## Text Input

### Commit message

```
response = ping("What should the commit message be?",
                input_type="text",
                default_value="fix: resolve race condition in queue worker")
```

### Custom configuration value

```
response = ping("What should the API rate limit be? (requests/minute)",
                input_type="text",
                default_value="100")
```

## Secure Input

### API key collection

```
response = ping("Enter the API key for the staging environment",
                input_type="secure_text")

// Value is masked in the dialog and never written to history
```

## Multi-Question Dialogs

### Service configuration wizard

```
response = ping("Configure the new service",
                input_type="questions",
                mode="wizard",
                questions=[
                  { id: "name", label: "Service name", type: "text" },
                  { id: "env", label: "Environment", type: "choice", options: ["dev", "staging", "prod"] },
                  { id: "features", label: "Features", type: "choice", options: ["logging", "metrics", "tracing"], multiSelect: true },
                  { id: "deploy", label: "Deploy immediately?", type: "confirmation" }
                ])

// response.response = { "name": "auth-api", "env": "staging", "features": ["logging", "metrics"], "deploy": "yes" }
// response.completed_count = 4
```

### Project setup accordion

```
response = ping("Set up the new project",
                input_type="questions",
                mode="accordion",
                questions=[
                  { id: "framework", label: "Framework", type: "choice", options: ["Next.js", "Remix", "Astro"] },
                  { id: "db", label: "Database", type: "choice", options: ["Postgres", "MySQL", "SQLite"] },
                  { id: "auth", label: "Auth provider", type: "choice", options: ["Supabase", "Clerk", "Auth.js"] }
                ])
```

## Notifications

### Build completion

```
ping("Build completed: 47 tests passed, binary at target/release/app (12.4 MB)",
     input_type="notify")
```

### Task progress

```
ping("Starting full test suite (~10 minutes). I'll ping when done.",
     input_type="notify")

// Run tests...

response = ping("Tests complete: 234 passed, 2 failed.",
                input_type="choice",
                options=["Show failures", "Continue", "Stop"])
```

## Handling Snooze

```
response = ping("Ready to deploy to staging?", input_type="confirmation")

if response.snoozed:
    // User snoozed for 15 minutes
    // Continue with other tasks (code review, documentation, etc.)
    // After retry_after_seconds, retry the question:
    response = ping("Ready to deploy to staging? (asking again after snooze)",
                    input_type="confirmation")
```

## Handling Feedback

```
response = ping("Should I add error handling to all 23 endpoints or just auth?",
                input_type="choice",
                options=["All endpoints", "Auth only", "Missing only"])

if response.feedback:
    // feedback_text = "Actually, skip error handling for now. Focus on the failing tests in auth module."
    // Shift focus to what the user actually wants
```

## Handling Comments

```
response = ping("Deploy to production?", input_type="confirmation")

if response.response == "yes":
    if response.comment:
        // comment = "skip migration step, we'll run it manually"
        // Adjust deployment to skip migrations
    // Proceed with deployment
```

## Build & Test Workflows

### Full test suite

```
User: "Run the tests and let me know when done"

Claude:
ping("Starting test suite. I'll notify you when complete.", input_type="notify")

// Run tests...
cargo test --all

response = ping("Tests done: 156 passed, 0 failed.",
                input_type="choice",
                options=["Show details", "Continue"])
```

### Build with potential failures

```
User: "Build the project, ping me if there are issues"

Claude:
cargo build --release 2>&1

// If failed:
response = ping("Build failed: 3 errors in auth module. See details above.",
                input_type="choice",
                options=["Show errors", "Try fix", "Cancel"])

// If succeeded:
ping("Build successful! Binary at target/release/app", input_type="notify")
```

## Multi-Step Workflows

### Complete feature implementation

```
User: "Implement the dashboard feature, check with me at key points"

Claude:
// Phase 1: Design
ping("Starting dashboard implementation. Designing component structure...", input_type="notify")
response = ping("Design ready: 4 components, state in context. Proceed?",
                input_type="confirmation")

// Phase 2: Build
ping("Building components. ~15 minutes.", input_type="notify")
response = ping("Components built. 847 lines across 4 files. Ready for styling?",
                input_type="choice",
                options=["Add styling", "Review code first", "More changes"])

// Phase 3: Complete
response = ping("Dashboard complete! Preview at localhost:3000/dashboard",
                input_type="choice",
                options=["Create PR", "More tweaks", "Show diff"])
```

## Advanced: Do Work While Waiting

```
ping("Starting deployment...", wait=false)

// Do some setup work while user hasn't responded yet...
prepare_rollback_plan()
verify_staging_health()

// Now block for the response
response = wait_for_response(timeout_seconds=600)
```
