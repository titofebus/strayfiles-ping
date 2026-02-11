# Release Signing Keys

This directory contains the public keys used to verify release binaries.

## Current Key

**File:** `strayfiles-ping.pub`
**Key ID:** (will be set after key generation)
**Algorithm:** Ed25519 (minisign)
**Created:** (will be set after key generation)
**Status:** Active

## Key Rotation History

None yet.

## Verification

To manually verify a binary:

```bash
minisign -Vm strayfiles-ping-macos-arm64 -p keys/strayfiles-ping.pub
```

## Private Key

⚠️ **The private key is NEVER stored in this repository.**

Private key location (maintainers only):
- Stored in 1Password vault
- Used during manual release signing
- File: `strayfiles-ping.key`

## Generating New Keys

See [docs/release-signing.md](../docs/release-signing.md) for full instructions.

Quick reference:
```bash
minisign -G -p strayfiles-ping.pub -s strayfiles-ping.key
```

## Key Fingerprint

After generation, add the key fingerprint here:

```
Algorithm: Ed25519
Key ID: (to be added)
Fingerprint: (to be added)
```
