---
name: Cloud Environment Setup
description: Set up Claude Code cloud/mobile environments for development. Use when starting a new cloud session, when tools are missing, or when user says "setup cloud", "setup environment", or mentions mobile Claude Code.
---

# Cloud Environment Setup

Set up a fresh cloud/mobile Claude Code environment with all tools needed for development.

## Quick Start

Run the setup script to install all required tools:

```bash
.claude/skills/cloud-setup/scripts/setup.sh
```

Or verify an existing environment:

```bash
.claude/skills/cloud-setup/scripts/verify.sh
```

## When to Use This Skill

Use this skill when:
- Starting a new cloud/mobile Claude Code session
- Required build tools are not found
- User says "setup cloud", "setup environment", "install tools"
- Build commands fail due to missing tools
- User mentions "mobile Claude Code" or "cloud environment"

## Configuration

Configure the setup for your project by setting these variables at the top of `scripts/setup.sh` and `scripts/verify.sh`, or via environment variables:

```bash
# REQUIRED: Tools your project needs (space-separated)
# The setup script will check for and install these
REQUIRED_TOOLS="git make"

# REQUIRED: Build command to run after setup
BUILD_CMD="make build"

# REQUIRED: Test command to verify the build
TEST_CMD="make test"

# OPTIONAL: Language-specific settings
PROJECT_LANG="auto"          # auto-detect, or: go, node, python, rust, java
PROJECT_LANG_VERSION=""      # e.g., "1.24" for Go, "22" for Node

# OPTIONAL: Verification command (runs a built artifact to confirm it works)
VERIFY_CMD=""                # e.g., "./bin/myapp --version"

# OPTIONAL: Extra environment variables needed for builds
BUILD_ENV_VARS=""            # e.g., "GOTOOLCHAIN=local GOPROXY=direct"
```

**Environment variable overrides:**
| Variable | Purpose |
|----------|---------|
| `REQUIRED_TOOLS` | Override required tool list |
| `BUILD_CMD` | Override build command |
| `TEST_CMD` | Override test command |
| `VERIFY_CMD` | Override verification command |
| `PROJECT_LANG` | Override language detection |
| `PROJECT_LANG_VERSION` | Override language version |

## Environment Requirements

### Common Required Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **git** | Version control | `apt-get install git` |
| **make** | Build automation | `apt-get install make` |
| **gh** | GitHub CLI | See setup script |
| **jq** | JSON processing | `apt-get install jq` |

### Language-Specific Tools

| Language | Tool | Minimum Version |
|----------|------|-----------------|
| Go | `go` | 1.24+ |
| Node.js | `node`, `npm` | 22+ |
| Python | `python3`, `pip3` | 3.10+ |
| Rust | `rustc`, `cargo` | 1.75+ |
| Java | `java`, `mvn`/`gradle` | 17+ |

### Resource Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 4 GB | 8+ GB |
| Disk | 5 GB free | 10+ GB |
| CPUs | 2 | 4+ |
| Network | Required | Required |

## Setup Workflow

### Step 1: Assess Current Environment

```bash
# Check what's available
which git make gh 2>/dev/null

# Detect project type
ls package.json go.mod Cargo.toml requirements.txt pom.xml build.gradle 2>/dev/null
```

### Step 2: Fix DNS (if needed)

Cloud environments sometimes have broken DNS:

```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
```

### Step 3: Install Build Tools

```bash
apt-get update && apt-get install -y make git jq
```

### Step 4: Install Language Runtime

Detect the project language from manifest files and install the appropriate runtime. See the setup script for auto-detection logic.

### Step 5: Install GitHub CLI

```bash
curl -L https://github.com/cli/cli/releases/download/v2.63.2/gh_2.63.2_linux_amd64.tar.gz -o /tmp/gh.tar.gz
tar -xzf /tmp/gh.tar.gz -C /tmp
mv /tmp/gh_*/bin/gh /usr/local/bin/
rm -rf /tmp/gh*
```

### Step 6: Build Project

```bash
# Install dependencies (language-specific)
# Go: go mod download
# Node: npm install
# Python: pip install -r requirements.txt
# Rust: cargo fetch

# Build
$BUILD_CMD
```

### Step 7: Verify

```bash
# Run verification command
$VERIFY_CMD

# Run tests
$TEST_CMD
```

## Available Scripts

### `scripts/setup.sh`

Full automated setup -- detects project type, installs tools, builds, and verifies.

**Usage:**
```bash
.claude/skills/cloud-setup/scripts/setup.sh
```

**What it does:**
1. Checks current environment
2. Fixes DNS if needed
3. Installs basic build tools (make, git)
4. Detects project language from manifest files
5. Installs language runtime
6. Installs GitHub CLI
7. Downloads dependencies and builds
8. Runs verification

### `scripts/verify.sh`

Verify environment is correctly set up.

**Usage:**
```bash
.claude/skills/cloud-setup/scripts/verify.sh
```

**Checks:**
- Required tools are installed and correct versions
- Project builds successfully
- Tests pass
- Network connectivity

## Resources

### Troubleshooting Guide
See [`resources/troubleshooting.md`](resources/troubleshooting.md) for common issues and solutions.

## Known Issues

### 1. DNS Resolution Failures

**Symptom:** `dial tcp: lookup ... on [::1]:53: connection refused`

**Solution:** Add Google DNS to `/etc/resolv.conf`:
```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2. SSL/TLS Handshake Failures

**Symptom:** `curl: (35) ... sslv3 alert handshake failure`

**Solution:** Use `wget --no-check-certificate` instead of `curl`

### 3. Missing Basic Commands

**Symptom:** `head`, `tail`, `grep` not found

**Solution:** Either install coreutils or avoid piping:
```bash
apt-get update && apt-get install -y coreutils grep
```

### 4. Package Manager Issues

**Symptom:** `apt-get` fails with malformed sources

**Solution:** Remove problematic source files:
```bash
rm -f /etc/apt/sources.list.d/problematic-file.list
apt-get update
```

## Post-Setup Checklist

After setup, verify you can:

- [ ] Required tools are all in PATH and correct versions
- [ ] `$BUILD_CMD` succeeds
- [ ] `$TEST_CMD` passes
- [ ] `gh --version` works (if GitHub operations needed)

## What You Can Do After Setup

With the environment configured, you can:

1. **Build project**: `$BUILD_CMD`
2. **Run tests**: `$TEST_CMD`
3. **Work on code**: Full read/write access
4. **Commit and push**: Git operations work
5. **GitHub operations**: Issues, PRs, releases via `gh`
