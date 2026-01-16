# Ping Examples

Detailed examples of using Strayfiles Ping in real scenarios.

**Note:** By default, `ping()` waits for the user to respond (up to 5 minutes). You don't need to call `wait_for_response()` separately unless you want to do work between sending and waiting.

## Build & Test Workflows

### Running a full test suite

```
User: "Run the tests and let me know when done"

Claude:
ping("Starting test suite. I'll notify you when complete.", wait=false)

// Run tests...
cargo test --all

// Tests complete - wait for user acknowledgment
response = ping("Tests done: 156 passed, 0 failed. All green!",
                options=["Great!", "Show details"])
```

### Build with potential failures

```
User: "Build the project, ping me if there are issues"

Claude:
// Start build
cargo build --release 2>&1

// If build fails - ping waits for response automatically
response = ping("Build failed: 3 errors in auth module. See details above.",
                options=["Show errors", "Try fix", "Cancel"])

// If build succeeds - fire-and-forget notification
ping("Build successful! Binary at target/release/app (12.4 MB)", wait=false)
```

### CI/CD pipeline

```
User: "Deploy to staging and let me know"

Claude:
ping("Starting staging deployment. ~5 min. I'll ping when ready.", wait=false)

// Run deployment steps...
git push origin staging
// Wait for CI...

// Now get user decision - waits up to 10 minutes
response = ping("Staging deploy complete. https://staging.app.com ready for testing.",
                options=["Deploy to prod", "Run smoke tests", "Rollback"],
                timeout_seconds=600)
```

## Code Review Workflows

### PR creation

```
User: "Create a PR for these changes, ping me when ready"

Claude:
// Analyze changes, write description...

response = ping("PR ready: 'Add user authentication' - 12 files, +450/-23 lines. Create it?",
                options=["Create PR", "Edit description", "Show summary"])

if response contains "Create PR":
    gh pr create --title "..." --body "..."
    ping("PR created: https://github.com/org/repo/pull/123", wait=false)
```

### Reviewing changes before commit

```
User: "Make those refactoring changes but check with me before committing"

Claude:
// Make changes across multiple files...

response = ping("Refactoring complete: 8 files changed. Ready to commit?",
                options=["Commit", "Show diff", "More changes"])
```

## Long-Running Tasks

### Database migration

```
User: "Run the database migration"

Claude:
ping("Starting DB migration. This may take several minutes. I'll ping when done or if issues arise.", wait=false)

// Run migration...
sqlx migrate run

// On success - simple notification
ping("Migration complete. 3 tables updated, 0 errors.", wait=false)

// On failure - need user decision
response = ping("Migration failed at step 4: constraint violation. See error above.",
                options=["Show details", "Rollback", "Skip step"])
```

### Large file processing

```
User: "Process all the log files in /var/log"

Claude:
ping("Processing 2.3 GB of logs across 847 files. ETA ~8 minutes.", wait=false)

// Process files...

ping("Log processing done. Found 23 errors, 156 warnings. Report saved to analysis.md", wait=false)
```

## Decision Points

### Multiple implementation options

```
User: "Fix the performance issue in the search function"

Claude:
// After analysis...

response = ping("Found 3 approaches to fix search performance:
1. Add index (quick, +15% speed)
2. Caching layer (moderate, +60% speed)
3. Rewrite algorithm (complex, +200% speed)
Which approach?",
     options=["1. Index", "2. Cache", "3. Rewrite", "Explain more"])
```

### Destructive operations

```
User: "Clean up the old branches"

Claude:
// Identify branches...

response = ping("Found 47 stale branches (>90 days old). Delete them?",
                options=["Delete all", "Show list", "Keep recent"])

if response contains "Delete all":
    // Delete branches...
    ping("Deleted 47 branches. Main and develop preserved.", wait=false)
```

### Ambiguous requirements

```
User: "Add error handling to the API"

Claude:
// After reviewing codebase...

response = ping("Should I add error handling to:
- All endpoints (23 routes)
- Just auth endpoints (5 routes)
- Only endpoints missing it (12 routes)?",
     options=["All", "Auth only", "Missing only"])
```

## Approval Workflows

### Before publishing

```
User: "Publish the new version"

Claude:
// Prepare release...

response = ping("Ready to publish v2.1.0 to npm. 34 packages affected. Proceed?",
                options=["Publish", "Dry run first", "Cancel"],
                timeout_seconds=600)
```

### Security-sensitive operations

```
User: "Update the production secrets"

Claude:
response = ping("About to update 3 production secrets:
- API_KEY (rotating)
- DB_PASSWORD (new)
- JWT_SECRET (rotating)
Confirm?",
     options=["Update all", "Show details", "Cancel"])
```

## Handling No Response

When `ping()` times out, it returns a helpful message (not an error). Handle gracefully:

### Timeout with graceful fallback

```
Claude:
response = ping("Build complete. Deploy to staging?", options=["Deploy", "Cancel"])

if response contains "timed out":
    // User didn't respond in 5 minutes
    "No response received. I'll skip the deployment - just let me know when you're ready."
```

### Retry for critical decisions

```
Claude:
response = ping("Production deploy ready. Need your approval.", options=["Deploy", "Cancel"])

if response contains "timed out":
    "Didn't get a response on the deploy approval. This is a production change so I'll wait for you to confirm in chat before proceeding."
```

## Multi-Step Workflows

### Complete feature implementation

```
User: "Implement the new dashboard feature, check with me at key points"

Claude:
// Phase 1: Design
ping("Starting dashboard implementation. First designing component structure...", wait=false)
// Design components...
response = ping("Design ready: 4 components, state in Redux. Proceed with implementation?",
                options=["Proceed", "Review design"])

// Phase 2: Implementation
ping("Building components. ~15 minutes. Will ping when ready for review.", wait=false)
// Build components...
response = ping("Components built. 847 lines across 4 files. Ready for styling?",
                options=["Add styling", "Review code first"])

// Phase 3: Complete
response = ping("Dashboard complete! Preview at localhost:3000/dashboard",
                options=["Create PR", "More tweaks"])
```
