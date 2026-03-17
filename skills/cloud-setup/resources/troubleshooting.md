# Cloud Setup Troubleshooting Guide

This guide covers common issues when setting up development environments in cloud/mobile Claude Code sessions.

## DNS Issues

### Symptom
```
dial tcp: lookup storage.googleapis.com on [::1]:53: read udp ... connection refused
```

### Cause
Cloud environment has no DNS configured or broken DNS resolution.

### Solution
```bash
# Add Google DNS servers
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
```

---

## SSL/TLS Handshake Failures

### Symptom
```
curl: (35) OpenSSL/3.0.13: error:0A000410:SSL routines::sslv3 alert handshake failure
```

### Cause
Some cloud environments have SSL/TLS issues with certain endpoints.

### Solution
Use `wget` with certificate checking disabled:
```bash
# Instead of curl:
wget --no-check-certificate https://example.com/file.tar.gz -O /tmp/file.tar.gz
```

---

## Missing Basic Commands

### Symptom
```
/bin/bash: line 1: head: command not found
/bin/bash: line 1: tail: command not found
/bin/bash: line 1: grep: command not found
```

### Cause
Minimal container image without coreutils.

### Solutions

**Option 1**: Install coreutils
```bash
apt-get update && apt-get install -y coreutils grep
```

**Option 2**: Avoid piping, run commands directly
```bash
# Instead of: command | head -20
# Just run: command
# And manually inspect output
```

---

## apt-get Issues

### Symptom
```
E: Malformed entry in list file
E: The list of sources could not be read
```

### Cause
Corrupted apt sources list.

### Solution
```bash
# Remove problematic source
rm -f /etc/apt/sources.list.d/problematic-file.list
apt-get update
```

---

## Go-Specific Issues

### Go Toolchain Auto-Download

**Symptom:**
```
go: downloading go1.24.11 (linux/amd64)
go: download go1.24.11: ... connection refused
```

**Solution:**
```bash
export GOTOOLCHAIN=local
```

### Go Module Proxy Blocked

**Symptom:**
```
Get "https://proxy.golang.org/...": i/o timeout
```

**Solution:**
```bash
export GOPROXY=direct
go mod download
```

### Go Version Mismatch

**Symptom:**
```
go: go.mod requires go >= 1.24
```

**Solution:** Install Go directly:
```bash
wget --no-check-certificate https://go.dev/dl/go1.24.4.linux-amd64.tar.gz -O /tmp/go.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
export PATH=/usr/local/go/bin:$PATH
```

---

## Node.js-Specific Issues

### Node Version Too Old

**Symptom:** Package requires newer Node version.

**Solution:**
```bash
# Install specific version via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
```

### npm Permission Errors

**Symptom:** `EACCES` errors during `npm install`.

**Solution:**
```bash
npm config set prefix ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
```

---

## Python-Specific Issues

### Missing pip

**Symptom:** `pip3: command not found`

**Solution:**
```bash
apt-get install -y python3-pip python3-venv
```

### Virtual Environment Issues

**Symptom:** `error: externally-managed-environment`

**Solution:**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

---

## Tests Hanging

### Symptom
Tests start running but hang indefinitely.

### Cause
Some tests may require network access that is blocked or slow in cloud environments.

### Solution
Run targeted tests instead of full suite:
```bash
# Run only unit tests (no network)
$TEST_CMD --short

# Or skip specific test packages
# (language-specific flags vary)
```

---

## GitHub CLI Authentication

### Symptom
```
gh: To use GitHub CLI, run 'gh auth login' first.
```

### Cause
gh CLI is installed but not authenticated.

### Solution
```bash
# Interactive login
gh auth login

# Or use token
gh auth login --with-token < token.txt

# Check status
gh auth status
```

---

## Build Failures

### Symptom
Build command exits with non-zero status.

### Common Fixes

**Missing dependencies:**
```bash
# Go
go mod download

# Node
npm install

# Python
pip install -r requirements.txt

# Rust
cargo fetch
```

**Wrong runtime version:** Install the correct version (see language-specific sections above).

**Network issues:** Try setting proxy/direct download environment variables.

---

## Quick Diagnostic Commands

```bash
# Check all tools
which git make gh

# Check network
curl -s --connect-timeout 5 https://api.github.com | head -1

# Check DNS
cat /etc/resolv.conf
host google.com

# Check disk space
df -h .

# Check memory
free -h
```

---

## Environment Variables Checklist

Common environment variables for cloud builds:

```bash
# Go
export PATH=/usr/local/go/bin:$PATH
export GOTOOLCHAIN=local
export GOPROXY=direct

# Node
export PATH=~/.npm-global/bin:$PATH

# Python
export PATH=~/.local/bin:$PATH

# Rust
source "$HOME/.cargo/env"
```
