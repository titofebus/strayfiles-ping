# Changelog

All notable changes to strayfiles-ping will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Native macOS dialogs** — local-first interaction system, no account needed
- **Seven input types** — confirmation, choice, multi-select, text, secure text, questions, notify
- **Dialog CLI** (`strayfiles-dialog`) — Swift binary for rendering native SwiftUI dialogs
- **Smart routing** — automatic local/remote decision based on user presence (Pro)
- **Snooze** — defer all dialogs for 1-60 minutes with global persistence
- **Inline feedback** — redirect the agent with free-form text instead of answering
- **Comment field** — attach optional notes alongside any response
- **Multi-question dialogs** — wizard (step-by-step) and accordion (collapsible sections) modes
- **Markdown support** in dialog messages (bold, italic, code, links)
- **Interaction history** — per-day JSON logs, queryable via CLI
- **Config system** — TOML config at `~/.config/strayfiles-ping/config.toml`
- **Config CLI** — `strayfiles-ping config set/get/list/reset`
- **History CLI** — `strayfiles-ping history [--last N] [--since DATE] [--search TEXT]`
- **Button cooldown** — configurable input blocking to prevent accidental keystrokes
- **Keyboard navigation** — full keyboard support for all dialog types
- **Accessibility** — VoiceOver labels, hints, system focus rings
- **Project context** — dialog shows project folder name with path tooltip
- **Timeout bar** — visual countdown indicator
- **Dialog sounds** — configurable system sounds (subtle, pop, chime)
- MIT License for open source release
- Secure token storage using system keychain (macOS Keychain, Linux Secret Service)
- Automatic migration from file-based to keychain storage
- Queue size limit (100 items maximum per user)
- Improved error messages with actionable guidance
- SPDX license headers on all source files

### Fixed
- Fixed critical queue consumption bug where queue items could be lost on network failures
- Fixed MCP protocol compliance issues (updated to 2025-11-25)
- Enabled auto-response rate limiting (10 per hour enforcement)

### Changed
- Options limit increased from 4 to 20
- Free tier now works without authentication (local dialogs)
- Skill file updated with all new input types and handling guidance
- Install script downloads both binaries on macOS
- Token storage moved from plaintext file to system keychain
- MCP protocol version updated from 2024-11-05 to 2025-11-25
- Logging now shows message length instead of full content in production logs
- Error handling improved with specific error types

### Security
- Tokens now stored in system keychain instead of plaintext files
- Automatic file cleanup after keychain migration
- Reduced logging verbosity to prevent sensitive data exposure
- Secure text input values never written to history

## [0.1.0] - 2025-01-15

### Added
- Initial release
- MCP server for AI agent notifications
- Ping tool for sending notifications to devices
- Wait tool for blocking until user responds
- Queue feature for pre-programmed auto-responses
- Authentication via Strayfiles account
- Integration with Supabase Realtime for instant responses
- Pro tier requirement enforcement
