# Contributing to Strayfiles Ping

Thank you for your interest in contributing! This document provides guidelines for contributing to the strayfiles-ping plugin.

## Development Setup

### Prerequisites

- Rust (stable channel): Install from [rustup.rs](https://rustup.rs)
- Git
- A Strayfiles account (for testing)

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/titofebus/strayfiles-ping.git
   cd strayfiles-ping
   ```

2. Build the project:
   ```bash
   cd server
   cargo build
   ```

3. Run tests:
   ```bash
   cargo test
   ```

4. Run the MCP server locally:
   ```bash
   cargo run
   ```

## Code Style

### Rust

- **Format**: Run `cargo fmt` before committing
- **Lint**: Run `cargo clippy --all-targets` and fix all warnings
- **Error Handling**: No `unwrap()`, `expect()`, or `panic!()` in library code
- **Documentation**: Add doc comments for public APIs

### Allowed Exceptions

CLI code (`main.rs`, auth command) can use:
- `println!()` for user output (it's a CLI tool)
- `std::fs::write()` (standalone binary without atomic write module)

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
- [ ] All tests pass (`cargo test`)
- [ ] Clippy passes (`cargo clippy --all-targets`)
- [ ] Code is formatted (`cargo fmt`)
- [ ] Documentation updated (if needed)
- [ ] CHANGELOG.md updated
- [ ] Commit messages follow guidelines

## Testing

### Unit Tests

```bash
cargo test
```

### Integration Tests

```bash
cargo test --test integration_tests
```

### Test Command

The `strayfiles-ping test` command sends a test notification:

```bash
cargo run -- test "Test message"
```

## Architecture

### Project Structure

```
strayfiles-ping/
├── plugin/              # Claude Code plugin files
│   ├── .claude-plugin/  # Plugin manifest
│   ├── skills/          # Claude Code skills
│   └── hooks/           # Git hooks
├── server/              # Rust MCP server
│   ├── src/
│   │   ├── main.rs      # CLI entry point
│   │   ├── mcp.rs       # MCP protocol implementation
│   │   ├── auth.rs      # Authentication flow
│   │   ├── keychain.rs  # Secure token storage
│   │   ├── supabase.rs  # Supabase client
│   │   ├── tools.rs     # MCP tools (ping, wait)
│   │   └── error.rs     # Error types
│   └── tests/           # Test suite
└── docs/                # Documentation

```

### Key Concepts

- **MCP Protocol**: JSON-RPC 2.0 based protocol for tool invocation
- **Supabase Integration**: Uses PostgREST API + Realtime WebSockets
- **Keychain Storage**: Platform-specific secure credential storage
- **Queue Feature**: FIFO auto-response system

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
