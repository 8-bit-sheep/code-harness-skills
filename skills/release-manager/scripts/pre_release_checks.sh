#!/usr/bin/env bash
# Run pre-release verification checks
#
# Environment variables:
#   TEST_CMD - Command to run tests (default: make test)
#   LINT_CMD - Command to run linter (default: make lint)

set -euo pipefail

TEST_CMD="${TEST_CMD:-make test}"
LINT_CMD="${LINT_CMD:-make lint}"

echo "Running pre-release checks..."
echo

FAILURES=0

# Test suite
echo "1/2 Running test suite..."
if $TEST_CMD > /tmp/pre_release_test.log 2>&1; then
    echo "  OK Tests passed"
else
    echo "  FAIL Tests failed"
    echo "  See: /tmp/pre_release_test.log"
    FAILURES=$((FAILURES + 1))
fi
echo

# Linting
echo "2/2 Running linter..."
if $LINT_CMD > /tmp/pre_release_lint.log 2>&1; then
    echo "  OK Linting passed"
else
    echo "  FAIL Linting failed"
    echo "  See: /tmp/pre_release_lint.log"
    FAILURES=$((FAILURES + 1))
fi
echo

# Summary
if [[ $FAILURES -eq 0 ]]; then
    echo "All pre-release checks passed!"
    echo "Ready to proceed with release."
    exit 0
else
    echo "$FAILURES check(s) failed"
    echo "Fix issues before proceeding with release."
    exit 1
fi
