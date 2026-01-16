# Changelog

All notable changes to strayfiles-ping will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fixed critical queue consumption bug where queue items could be lost on network failures
- Fixed MCP protocol compliance issues (updated to 2025-11-25)
- Enabled auto-response rate limiting (10 per hour enforcement)

### Added
- MIT License for open source release
- Secure token storage using system keychain (macOS Keychain, Linux Secret Service)
- Automatic migration from file-based to keychain storage
- Queue size limit (100 items maximum per user)
- Improved error messages with actionable guidance
- SPDX license headers on all source files

### Changed
- Token storage moved from plaintext file to system keychain
- MCP protocol version updated from 2024-11-05 to 2025-11-25
- Logging now shows message length instead of full content in production logs
- Error handling improved with specific error types (TokenRefreshFailed, ServiceUnavailable, RateLimitExceeded, QueueLimitExceeded)

### Security
- Tokens now stored in system keychain instead of plaintext files
- Automatic file cleanup after keychain migration
- Reduced logging verbosity to prevent sensitive data exposure

## [0.1.0] - 2025-01-XX

### Added
- Initial release
- MCP server for AI agent notifications
- Ping tool for sending notifications to devices
- Wait tool for blocking until user responds
- Queue feature for pre-programmed auto-responses
- Authentication via Strayfiles account
- Integration with Supabase Realtime for instant responses
- Pro tier requirement enforcement
