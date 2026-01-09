# Strayfiles Ping

Get notified on your phone when AI tasks complete. Say "ping me when done" and Claude will actually ping you.

## What It Does

- **Task notifications**: Get pinged when builds, tests, or deployments finish
- **Approval requests**: Claude can ask for approval before destructive actions
- **Cross-device**: Notifications appear on iOS, macOS, and the TUI
- **Quick replies**: Respond with buttons or custom text right from the notification

## Prerequisites

- **Strayfiles Pro** subscription
- **Strayfiles app** installed on at least one device (iOS, macOS, or TUI)

## Installation

```bash
# Install the plugin
claude plugin install https://github.com/strayfiles/strayfiles-ping.git

# Authenticate with your Strayfiles account
strayfiles-ping auth
```

## Usage

Just tell Claude naturally:

- "Run the tests and ping me when done"
- "Deploy to staging, but ping me for approval first"
- "Let me know if the build fails"
- "Notify me when you're finished"

Claude will automatically use Ping for long-running tasks like:
- Full test suites
- Large refactors
- Database migrations
- Build and deploy pipelines

## How It Works

1. You ask Claude to do something and ping you
2. Claude runs the task
3. When done (or when approval is needed), a notification appears on your devices
4. You respond from your phone, Mac, or TUI
5. Claude continues based on your response

## Troubleshooting

**"Notifications not appearing"**
- Check Strayfiles settings: Ping must be enabled
- Verify notification permissions in System Settings (Mac) or Settings app (iOS)
- Make sure you're signed into the same Strayfiles account

**"strayfiles-ping command not found"**
- Run the install script: `./install.sh`
- Or manually install: `cargo install --path /path/to/ping-mcp`

**"Authentication failed"**
- Run `strayfiles-ping auth` again
- Check your internet connection
- Verify your Strayfiles Pro subscription is active

## Links

- [Documentation](https://strayfiles.com/docs/pro/ping)
- [Strayfiles](https://strayfiles.com)
