#!/usr/bin/env bash
# Validate prerequisites before starting sprint execution
#
# Environment variables:
#   TEST_CMD - Command to run tests (default: make test)
#   LINT_CMD - Command to run linter (default: make lint)

set -euo pipefail

TEST_CMD="${TEST_CMD:-make test}"
LINT_CMD="${LINT_CMD:-make lint}"

echo "Validating sprint prerequisites..."
echo

FAILURES=0

# 1. Check working directory is clean
echo "1/4 Checking working directory..."
if [[ -z $(git status --short) ]]; then
    echo "  OK Working directory clean"
else
    echo "  WARNING Working directory has uncommitted changes:"
    git status --short | head -10
    echo "  Consider committing or stashing before starting sprint"
fi
echo

# 2. Check current branch
echo "2/4 Checking current branch..."
BRANCH=$(git branch --show-current)
echo "  On branch: $BRANCH"
echo

# 3. Run tests
echo "3/4 Running tests..."
if $TEST_CMD > /tmp/sprint_prereq_test.log 2>&1; then
    echo "  OK All tests pass"
else
    echo "  FAIL Tests failing"
    echo "  See: /tmp/sprint_prereq_test.log"
    FAILURES=$((FAILURES + 1))
fi
echo

# 4. Run linting
echo "4/4 Running linter..."
if $LINT_CMD > /tmp/sprint_prereq_lint.log 2>&1; then
    echo "  OK Linting passes"
else
    echo "  FAIL Linting fails"
    echo "  See: /tmp/sprint_prereq_lint.log"
    FAILURES=$((FAILURES + 1))
fi
echo

# Summary
if [[ $FAILURES -eq 0 ]]; then
    echo "All prerequisites validated!"
    echo "Ready to start sprint execution."
    exit 0
else
    echo "$FAILURES prerequisite(s) failed"
    echo "Fix issues before starting sprint."
    exit 1
fi
