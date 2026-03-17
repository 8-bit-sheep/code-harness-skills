#!/usr/bin/env bash
# Verify cloud environment is correctly configured
#
# Configuration (set these or override via environment variables):
#   REQUIRED_TOOLS     - Space-separated list of required tools (default: "git make")
#   BUILD_CMD          - Command to build the project (default: "make build")
#   TEST_CMD           - Command to run tests (default: "make test")
#   VERIFY_CMD         - Command to verify the build (optional)

set -euo pipefail

# ---- Configuration (override via environment) ----
REQUIRED_TOOLS="${REQUIRED_TOOLS:-git make}"
BUILD_CMD="${BUILD_CMD:-make build}"
TEST_CMD="${TEST_CMD:-make test}"
VERIFY_CMD="${VERIFY_CMD:-}"

echo "=========================================="
echo "Environment Verification"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() { echo -e "${GREEN}ok${NC} $1"; }
fail() { echo -e "${RED}FAIL${NC} $1"; }
warn() { echo -e "${YELLOW}WARN${NC} $1"; }

FAILURES=0
WARNINGS=0

echo "Checking required tools..."
echo ""

# Check each required tool
for TOOL in $REQUIRED_TOOLS; do
    if command -v "$TOOL" &> /dev/null; then
        VERSION=$("$TOOL" --version 2>/dev/null | head -1 || echo "installed")
        success "$TOOL: $VERSION"
    else
        fail "$TOOL: not found"
        FAILURES=$((FAILURES + 1))
    fi
done

# Check gh (optional but useful)
if command -v gh &> /dev/null; then
    success "gh: $(gh --version 2>/dev/null | head -1 | awk '{print $3}')"
else
    warn "gh: not found (optional for GitHub operations)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Detecting project language..."
echo ""

# Detect language and check runtime
if [ -f "go.mod" ]; then
    if command -v go &> /dev/null; then
        GO_VER=$(go version 2>/dev/null | awk '{print $3}')
        success "Go: $GO_VER"
    else
        fail "Go: not found (go.mod present)"
        FAILURES=$((FAILURES + 1))
    fi
elif [ -f "package.json" ]; then
    if command -v node &> /dev/null; then
        success "Node: $(node --version)"
    else
        fail "Node: not found (package.json present)"
        FAILURES=$((FAILURES + 1))
    fi
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    if command -v python3 &> /dev/null; then
        success "Python: $(python3 --version 2>&1 | awk '{print $2}')"
    else
        fail "Python: not found (requirements.txt/pyproject.toml present)"
        FAILURES=$((FAILURES + 1))
    fi
elif [ -f "Cargo.toml" ]; then
    if command -v rustc &> /dev/null; then
        success "Rust: $(rustc --version | awk '{print $2}')"
    else
        fail "Rust: not found (Cargo.toml present)"
        FAILURES=$((FAILURES + 1))
    fi
elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    if command -v java &> /dev/null; then
        success "Java: $(java --version 2>&1 | head -1)"
    else
        fail "Java: not found (pom.xml/build.gradle present)"
        FAILURES=$((FAILURES + 1))
    fi
else
    warn "Could not detect project language"
    WARNINGS=$((WARNINGS + 1))
fi

# Run verification command if set
if [ -n "$VERIFY_CMD" ]; then
    echo ""
    echo "Running verification command..."
    echo ""

    if $VERIFY_CMD 2>&1; then
        success "Verification passed: $VERIFY_CMD"
    else
        fail "Verification failed: $VERIFY_CMD"
        FAILURES=$((FAILURES + 1))
    fi
fi

echo ""
echo "Checking network..."
echo ""

# Check network connectivity
if curl -s --connect-timeout 5 -o /dev/null https://api.github.com 2>/dev/null; then
    success "Network: GitHub API accessible"
else
    warn "Network: GitHub API not accessible"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "Running quick tests..."
echo ""

# Run test command
if $TEST_CMD > /tmp/verify_test.log 2>&1; then
    success "Tests pass: $TEST_CMD"
else
    fail "Tests fail -- see /tmp/verify_test.log"
    FAILURES=$((FAILURES + 1))
fi

echo ""
echo "=========================================="

if [[ $FAILURES -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo ""
    echo "Environment is fully configured and ready."
elif [[ $FAILURES -eq 0 ]]; then
    echo -e "${YELLOW}Passed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Environment is usable but may have minor issues."
else
    echo -e "${RED}$FAILURES check(s) failed${NC}"
    echo ""
    echo "Run setup script to fix:"
    echo "  .claude/skills/cloud-setup/scripts/setup.sh"
    exit 1
fi
echo "=========================================="
