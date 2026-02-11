# Binary Release Signing

This document explains how to sign release binaries for strayfiles-ping using Ed25519 signatures.

## Overview

All release binaries are signed with Ed25519 to ensure integrity and prevent tampering. The install script verifies signatures before installation.

## Key Generation (One-Time Setup)

### Using minisign (Recommended)

```bash
# Install minisign
brew install minisign  # macOS
apt-get install minisign  # Linux

# Generate keypair
minisign -G -p strayfiles-ping.pub -s strayfiles-ping.key

# Secure the private key
chmod 600 strayfiles-ping.key
mv strayfiles-ping.key ~/.ssh/  # Store securely
```

**Output:**
- `strayfiles-ping.pub` - Public key (commit to repo in `keys/`)
- `strayfiles-ping.key` - Private key (NEVER commit, store in 1Password/Vault)

### Using OpenSSL (Alternative)

```bash
# Generate Ed25519 keypair
openssl genpkey -algorithm ED25519 -out strayfiles-ping-private.pem

# Extract public key
openssl pkey -in strayfiles-ping-private.pem -pubout -out strayfiles-ping-public.pem

# Secure the private key
chmod 600 strayfiles-ping-private.pem
mv strayfiles-ping-private.pem ~/.ssh/
```

## Signing Release Binaries

### Automated (CI/CD)

Add private key to GitHub Secrets:

```yaml
# .github/workflows/release.yml
env:
  MINISIGN_KEY: ${{ secrets.MINISIGN_PRIVATE_KEY }}
  MINISIGN_PASSWORD: ${{ secrets.MINISIGN_PASSWORD }}
```

### Manual Signing

```bash
# Sign a binary
minisign -Sm strayfiles-ping-macos-arm64 -s ~/.ssh/strayfiles-ping.key

# This creates: strayfiles-ping-macos-arm64.minisig

# Verify signature
minisign -Vm strayfiles-ping-macos-arm64 -p keys/strayfiles-ping.pub
```

### Sign All Platform Binaries

```bash
#!/bin/bash
# scripts/sign-releases.sh

BINARIES=(
  "strayfiles-ping-macos-arm64"
  "strayfiles-ping-macos-x64"
  "strayfiles-ping-linux-x64"
  "strayfiles-ping-linux-arm64"
)

for binary in "${BINARIES[@]}"; do
  echo "Signing $binary..."
  minisign -Sm "$binary" -s ~/.ssh/strayfiles-ping.key
done

echo "All binaries signed!"
```

## Public Key Distribution

The public key is embedded in the install script for verification:

```bash
# install.sh
PUBLIC_KEY="RWS... (base64 encoded public key)"
```

**Never change the public key once released** - this breaks verification for existing users.

## Signature Format

Minisign signatures are 104 bytes:
- Algorithm identifier (2 bytes)
- Key ID (8 bytes)
- Signature (64 bytes)
- Trusted comment (variable)

## Verification Process

The install script verifies signatures as follows:

```bash
# 1. Download binary and signature
curl -L -o strayfiles-ping "$BINARY_URL"
curl -L -o strayfiles-ping.minisig "$SIGNATURE_URL"

# 2. Verify signature
minisign -Vm strayfiles-ping -p <(echo "$PUBLIC_KEY")

# 3. Install only if verification succeeds
if [ $? -eq 0 ]; then
  install strayfiles-ping /usr/local/bin/
else
  echo "❌ Signature verification failed!"
  exit 1
fi
```

## Key Rotation

If the private key is compromised:

1. Generate new keypair
2. Sign all existing releases with new key
3. Update public key in install script
4. Increment version and announce key rotation
5. Keep old key valid for 90 days (transition period)

## Security Best Practices

### Private Key Storage

- **DO NOT** commit private key to git
- **DO NOT** share private key in Slack/email
- **DO** store in 1Password/Vault with team access
- **DO** use CI/CD secrets for automated signing
- **DO** require password for private key

### Public Key Distribution

- **DO** commit public key to `keys/` directory
- **DO** embed public key in install script
- **DO** publish public key on website
- **DO** include key ID in signature for verification

### Signature Verification

- **ALWAYS** verify before installation
- **NEVER** skip verification in install script
- **FAIL** installation if signature is invalid
- **WARN** if signature is missing (dev builds)

## Testing

### Test Signature Verification

```bash
# Good signature
minisign -Vm strayfiles-ping -p keys/strayfiles-ping.pub
# Should output: Signature and comment signature verified

# Tampered binary
echo "malware" >> strayfiles-ping
minisign -Vm strayfiles-ping -p keys/strayfiles-ping.pub
# Should output: Signature verification failed

# Missing signature
rm strayfiles-ping.minisig
./install.sh
# Should fail with: Signature file not found
```

## Release Process

1. Build binaries for all platforms
2. Sign each binary with `minisign`
3. Upload binaries + signatures via `scripts/release.sh` (Supabase Storage)
4. Test install script on each platform: `curl -fsSL https://strayfiles.com/ping-install.sh | sh`

## Troubleshooting

### "Command not found: minisign"

Install minisign:
```bash
brew install minisign  # macOS
apt-get install minisign  # Linux
```

### "Signature verification failed"

- Binary was tampered with
- Wrong public key used
- Signature file corrupted
- Binary/signature version mismatch

### "Password incorrect"

Private key is password-protected. Use:
```bash
minisign -Sm binary -s key -W  # Prompt for password
```

## References

- [minisign GitHub](https://github.com/jedisct1/minisign)
- [Ed25519 Specification](https://ed25519.cr.yp.to/)
- [Sigstore (future alternative)](https://www.sigstore.dev/)
