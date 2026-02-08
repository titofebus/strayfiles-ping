# Contributing to Strayfiles Ping

Thank you for your interest in contributing! This document provides guidelines for contributing to the strayfiles-ping plugin.

## Development Setup

### Prerequisites

- Swift 5.9+ (Xcode 15+ on macOS): For the dialog CLI
- Git
- macOS 14+ (for dialog development)

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/titofebus/strayfiles-ping.git
   cd strayfiles-ping
   ```

2. Build the dialog CLI:
   ```bash
   cd dialog
   swift build
   ```

3. Run tests:
   ```bash
   cd dialog
   swift test
   ```

4. Build a release universal binary:
   ```bash
   cd dialog
   swift build -c release --arch arm64 --arch x86_64
   ```

## Code Style

### Swift

- **Lint**: Run `swiftlint lint --strict` before committing
- **Error Handling**: No force unwrapping (`!`) — use `guard let`, `if let`, or `??`
- **Documentation**: Add doc comments for public APIs
- **No animations**: Use `.animation(nil)` — no custom transitions

### Git Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Reference issue numbers when applicable
- Keep first line under 72 characters

Example:
```
Fix queue transaction race condition (#42)

- Use atomic SQL function for queue consumption
- Add FOR UPDATE SKIP LOCKED to prevent races
- Include rate limit check in transaction
```

## Pull Request Process

1. **Fork** the repository
2. **Create a feature branch** from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Add tests for new functionality
   - Update documentation as needed
   - Run `cargo fmt` and `cargo clippy`

4. **Update CHANGELOG.md** under the `[Unreleased]` section

5. **Submit a pull request**
   - Provide a clear description of the changes
   - Link to any related issues
   - Ensure CI passes

### Pull Request Checklist

- [ ] Code follows project style guidelines
- [ ] All tests pass (`swift test` in `dialog/`)
- [ ] SwiftLint passes (`swiftlint lint --strict` in `dialog/`)
- [ ] Documentation updated (if needed)
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow guidelines

## Testing

### Unit Tests

```bash
cd dialog
swift test
```

### Manual Testing

Test the dialog CLI directly:

```bash
cd dialog
swift build
.build/debug/strayfiles-dialog --json '{"message":"Test","input_type":"confirmation"}'
```

## Architecture

### Project Structure

```
strayfiles-ping/
├── .claude-plugin/      # Plugin manifest
├── dialog/              # Swift dialog CLI (macOS native)
│   ├── Package.swift
│   ├── Sources/StrayfilesDialog/
│   │   ├── main.swift           # CLI entry point
│   │   ├── App/                 # NSApplication setup
│   │   ├── Config/              # TOML config reader
│   │   ├── Models/              # Response, type enums
│   │   ├── Views/               # SwiftUI dialog views
│   │   ├── Window/              # Borderless window, positioning
│   │   └── Utils/               # Keyboard, accessibility, sound
│   └── Tests/
├── skills/              # Claude Code skills
├── hooks/               # Git hooks
├── docs/                # Documentation
└── install.sh           # Install script
```

### Key Concepts

- **MCP Protocol**: JSON-RPC 2.0 based protocol for tool invocation
- **Dialog CLI**: Swift binary that renders native SwiftUI dialogs on macOS
- **Config System**: Shared TOML config at `~/.config/strayfiles-ping/config.toml`
- **Input Types**: Seven dialog types (confirmation, choice, multi_select, text, secure_text, questions, notify)
- **Snooze/Feedback**: Global snooze system and inline feedback for redirecting agents

## Security Guidelines

- Never commit API keys, tokens, or credentials
- Use environment variables for secrets
- Keep the `.env` file in `.gitignore`
- Report security issues privately to security@strayfiles.com

## Reporting Bugs

### Before Submitting

- Check existing issues for duplicates
- Verify the bug with the latest version
- Collect relevant information (OS, Rust version, logs)

### Bug Report Template

```markdown
**Description**
A clear description of the bug.

**To Reproduce**
Steps to reproduce the behavior:
1. Run command '...'
2. See error

**Expected Behavior**
What you expected to happen.

**Environment**
- OS: [e.g. macOS 14.1]
- Rust version: [e.g. 1.75.0]
- strayfiles-ping version: [e.g. 0.1.0]

**Logs**
```
Paste relevant logs here
```
```

## Feature Requests

We welcome feature requests! Please:

1. Check if the feature already exists or is planned
2. Describe the use case clearly
3. Explain why it would be useful
4. Provide examples if applicable

## Code of Conduct

Be respectful, inclusive, and professional in all interactions.

## Questions?

- Open a [GitHub Discussion](https://github.com/titofebus/strayfiles-ping/discussions)
- Check the [documentation](https://strayfiles.com/docs/pro/ping)
- Email: support@strayfiles.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
