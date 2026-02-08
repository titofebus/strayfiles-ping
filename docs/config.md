# Configuration

Strayfiles Ping uses a TOML config file at `~/.config/strayfiles-ping/config.toml`.

Both the MCP server (`strayfiles-ping`) and dialog CLI (`strayfiles-dialog`) read this file on every invocation. Any application can write this file to configure behavior.

## Managing Config

```bash
# Set a value
strayfiles-ping config set dialog.timeout 300

# Get a value
strayfiles-ping config get dialog.timeout

# List all settings
strayfiles-ping config list

# Reset to defaults
strayfiles-ping config reset
```

## Full Schema

```toml
[dialog]
# Enable native macOS dialogs
# Default: true
enabled = true

# Dialog position on screen
# Options: "top-right", "center", "top-left", "bottom-right"
# Default: "top-right"
position = "top-right"

# Timeout in seconds before dialog auto-dismisses
# Range: 1-3600
# Default: 600
timeout = 600

# Sound played when dialog appears
# Options: "none", "subtle", "pop", "chime"
# Default: "none"
sound = "none"

# Keep dialog above all other windows
# Default: true
always_on_top = true

# Block input briefly after dialog appears to prevent accidental keystrokes
# Default: false
cooldown = false

# Duration of input cooldown in seconds
# Range: 0.1-3.0
# Default: 1.0
cooldown_duration = 1.0

[theme]
# Accent color for buttons, selection highlights, and focus rings
# Hex color string (e.g., "#6366f1")
# Default: "" (uses macOS system accent color)
accent = ""

[routing]
# Seconds of inactivity before user is considered idle
# Range: 30-600
# Default: 120
idle_threshold = 120

# Routing preference for Pro users
# Options: "auto", "local", "remote"
#   auto   - smart routing based on presence detection
#   local  - always use native dialog (fail if unavailable)
#   remote - always use push notification (Pro only)
# Default: "auto"
prefer = "auto"

[snooze]
# ISO 8601 timestamp when snooze expires
# Empty string or missing = not snoozed
# Set automatically when user snoozes a dialog
# Default: ""
until = ""
```

## Defaults

When the config file is missing or a field is absent, these defaults apply:

| Field | Default |
|-------|---------|
| `dialog.enabled` | `true` |
| `dialog.position` | `"top-right"` |
| `dialog.timeout` | `600` |
| `dialog.sound` | `"none"` |
| `dialog.always_on_top` | `true` |
| `dialog.cooldown` | `false` |
| `dialog.cooldown_duration` | `1.0` |
| `theme.accent` | `""` (system default) |
| `routing.idle_threshold` | `120` |
| `routing.prefer` | `"auto"` |
| `snooze.until` | `""` (not snoozed) |

## Config Hierarchy

When multiple sources set the same value, highest priority wins:

```
1. Application preferences      (highest — if a managing app is installed)
2. User's config.toml           (manual CLI configuration)
3. Built-in defaults             (lowest — minimalist, system-native)
```

All sources write to the same `config.toml` file. The hierarchy is enforced by write order (an application may overwrite CLI settings when it syncs preferences).

## Integration

Any application can read and write this config file:

- **Read**: Parse `~/.config/strayfiles-ping/config.toml` as TOML
- **Write**: Write TOML to the same path (create directories if needed)
- **Watch**: Both binaries re-read config on every invocation, so changes take effect on the next dialog

The config format is the public contract. The MCP has zero knowledge of what writes the config.

## Sound Types

| Value | System Sound | Description |
|-------|-------------|-------------|
| `"none"` | — | Silent (default) |
| `"subtle"` | Tink | Soft tap sound |
| `"pop"` | Pop | Brief pop sound |
| `"chime"` | Glass | Glass chime sound |

## Position Options

| Value | Location |
|-------|----------|
| `"top-right"` | Upper-right corner (default) |
| `"center"` | Center of screen |
| `"top-left"` | Upper-left corner |
| `"bottom-right"` | Lower-right corner |

All positions respect the macOS menu bar and dock by using the screen's visible frame. A 16pt padding is applied from edges.
