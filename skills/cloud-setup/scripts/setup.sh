#!/usr/bin/env bash
# Cloud Environment Setup
# Detects project type, installs required tools, builds, and verifies.
#
# Configuration (set these or override via environment variables):
#   REQUIRED_TOOLS     - Space-separated list of required tools (default: "git make")
#   BUILD_CMD          - Command to build the project (default: "make build")
#   TEST_CMD           - Command to run tests (default: "make test")
#   VERIFY_CMD         - Command to verify the build (optional)
#   PROJECT_LANG       - Language: auto, go, node, python, rust (default: "auto")
#   PROJECT_LANG_VERSION - Required language version (optional)
#   BUILD_ENV_VARS     - Extra env vars for builds (optional, e.g., "FOO=bar BAZ=qux")

set -euo pipefail

# ---- Configuration (override via environment) ----
REQUIRED_TOOLS="${REQUIRED_TOOLS:-git make}"
BUILD_CMD="${BUILD_CMD:-make build}"
TEST_CMD="${TEST_CMD:-make test}"
VERIFY_CMD="${VERIFY_CMD:-}"
PROJECT_LANG="${PROJECT_LANG:-auto}"
PROJECT_LANG_VERSION="${PROJECT_LANG_VERSION:-}"
BUILD_ENV_VARS="${BUILD_ENV_VARS:-}"

echo "=========================================="
echo "Cloud Environment Setup"
echo "=========================================="
echo ""

# Colors (if supported)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}ok${NC} $1"; }
fail() { echo -e "${RED}FAIL${NC} $1"; }
warn() { echo -e "${YELLOW}WARN${NC} $1"; }
info() { echo "-> $1"; }

FAILURES=0

# Step 1: Check current environment
echo "Step 1/7: Assessing current environment..."
echo ""

info "System info:"
echo "  RAM: $(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo 'unknown')"
echo "  CPUs: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 'unknown')"
echo "  Disk: $(df -h . 2>/dev/null | awk 'NR==2 {print $4}' || echo 'unknown') available"
echo ""

# Step 2: Fix DNS if needed
echo "Step 2/7: Checking DNS..."

if ! host google.com > /dev/null 2>&1; then
    warn "DNS not working, configuring Google DNS..."
    if [ -w /etc/resolv.conf ]; then
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        success "DNS configured"
    else
        warn "Cannot write /etc/resolv.conf (no root access). DNS may not work."
    fi
else
    success "DNS working"
fi
echo ""

# Step 3: Install basic tools
echo "Step 3/7: Installing basic tools..."

for TOOL in $REQUIRED_TOOLS; do
    if command -v "$TOOL" &> /dev/null; then
        success "$TOOL already installed"
    else
        info "Installing $TOOL..."
        if command -v apt-get &> /dev/null; then
            apt-get update -qq 2>/dev/null
            apt-get install -y -qq "$TOOL" 2>/dev/null && success "$TOOL installed" || warn "Failed to install $TOOL via apt-get"
        elif command -v brew &> /dev/null; then
            brew install "$TOOL" 2>/dev/null && success "$TOOL installed" || warn "Failed to install $TOOL via brew"
        else
            fail "Cannot install $TOOL: no package manager found"
            FAILURES=$((FAILURES + 1))
        fi
    fi
done
echo ""

# Step 4: Detect and install language runtime
echo "Step 4/7: Setting up language runtime..."

detect_language() {
    if [ "$PROJECT_LANG" != "auto" ]; then
        echo "$PROJECT_LANG"
        return
    fi
    if [ -f "go.mod" ]; then echo "go"
    elif [ -f "package.json" ]; then echo "node"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then echo "python"
    elif [ -f "Cargo.toml" ]; then echo "rust"
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then echo "java"
    else echo "unknown"
    fi
}

LANG_DETECTED=$(detect_language)
info "Detected language: $LANG_DETECTED"

case "$LANG_DETECTED" in
    go)
        GO_VERSION="${PROJECT_LANG_VERSION:-1.24.4}"
        GO_INSTALLED=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "none")

        if [[ "$GO_INSTALLED" == "${GO_VERSION%.*}"* ]]; then
            success "Go $GO_INSTALLED already installed"
        else
            info "Installing Go $GO_VERSION..."
            if command -v wget &> /dev/null; then
                wget --no-check-certificate -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
            else
                curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
            fi
            rm -rf /usr/local/go
            tar -C /usr/local -xzf /tmp/go.tar.gz
            rm /tmp/go.tar.gz
            success "Go $GO_VERSION installed"
        fi
        export PATH=/usr/local/go/bin:$PATH
        ;;

    node)
        NODE_VERSION="${PROJECT_LANG_VERSION:-22}"
        if command -v node &> /dev/null; then
            success "Node $(node --version) already installed"
        else
            info "Installing Node.js $NODE_VERSION..."
            if command -v apt-get &> /dev/null; then
                curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
                apt-get install -y nodejs
            fi
            success "Node.js installed"
        fi
        ;;

    python)
        if command -v python3 &> /dev/null; then
            success "Python $(python3 --version 2>&1 | awk '{print $2}') already installed"
        else
            info "Installing Python..."
            if command -v apt-get &> /dev/null; then
                apt-get update -qq && apt-get install -y python3 python3-pip python3-venv
            fi
            success "Python installed"
        fi
        ;;

    rust)
        if command -v rustc &> /dev/null; then
            success "Rust $(rustc --version | awk '{print $2}') already installed"
        else
            info "Installing Rust..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
            success "Rust installed"
        fi
        ;;

    java)
        if command -v java &> /dev/null; then
            success "Java already installed"
        else
            info "Installing Java..."
            if command -v apt-get &> /dev/null; then
                apt-get update -qq && apt-get install -y default-jdk
            fi
            success "Java installed"
        fi
        ;;

    unknown)
        warn "Could not detect project language. Skipping runtime install."
        ;;
esac
echo ""

# Step 5: Install GitHub CLI
echo "Step 5/7: Installing GitHub CLI..."

GH_VERSION="2.63.2"

if command -v gh &> /dev/null; then
    success "gh already installed: $(gh --version 2>/dev/null | head -1)"
else
    info "Downloading gh $GH_VERSION..."

    if command -v wget &> /dev/null; then
        wget --no-check-certificate -q "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -O /tmp/gh.tar.gz
    else
        curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -o /tmp/gh.tar.gz
    fi

    info "Installing gh..."
    tar -xzf /tmp/gh.tar.gz -C /tmp
    mv /tmp/gh_${GH_VERSION}_linux_amd64/bin/gh /usr/local/bin/
    rm -rf /tmp/gh*

    success "gh $GH_VERSION installed"
fi
echo ""

# Step 6: Install dependencies and build
echo "Step 6/7: Building project..."

# Apply build environment variables
if [ -n "$BUILD_ENV_VARS" ]; then
    info "Setting build environment: $BUILD_ENV_VARS"
    export $BUILD_ENV_VARS
fi

# Language-specific dependency installation
case "$LANG_DETECTED" in
    go)
        export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
        export GOPROXY="${GOPROXY:-direct}"
        info "Downloading Go modules..."
        go mod download
        ;;
    node)
        info "Installing npm dependencies..."
        npm install
        ;;
    python)
        if [ -f "requirements.txt" ]; then
            info "Installing Python dependencies..."
            pip3 install -r requirements.txt
        elif [ -f "pyproject.toml" ]; then
            info "Installing Python project..."
            pip3 install -e .
        fi
        ;;
    rust)
        info "Fetching Rust dependencies..."
        cargo fetch
        ;;
    java)
        info "Dependencies will be fetched during build."
        ;;
esac

info "Running build: $BUILD_CMD"
if $BUILD_CMD; then
    success "Build succeeded"
else
    fail "Build failed"
    FAILURES=$((FAILURES + 1))
fi
echo ""

# Step 7: Verify
echo "Step 7/7: Verification..."

# Run verification command if set
if [ -n "$VERIFY_CMD" ]; then
    info "Running verification: $VERIFY_CMD"
    if $VERIFY_CMD 2>&1; then
        success "Verification passed"
    else
        fail "Verification failed"
        FAILURES=$((FAILURES + 1))
    fi
fi

# Run quick test
info "Running tests: $TEST_CMD"
if $TEST_CMD > /tmp/setup_test.log 2>&1; then
    success "Tests pass"
else
    warn "Some tests failed -- see /tmp/setup_test.log"
fi
echo ""

# Summary
echo "=========================================="
if [[ $FAILURES -eq 0 ]]; then
    echo -e "${GREEN}Setup Complete!${NC}"
    echo ""
    echo "Environment ready. You can now:"
    echo "  Build:  $BUILD_CMD"
    echo "  Test:   $TEST_CMD"
    if [ -n "$VERIFY_CMD" ]; then
        echo "  Verify: $VERIFY_CMD"
    fi
else
    echo -e "${RED}Setup had $FAILURES failure(s)${NC}"
    echo "Check the errors above and try again."
    exit 1
fi
echo "=========================================="
