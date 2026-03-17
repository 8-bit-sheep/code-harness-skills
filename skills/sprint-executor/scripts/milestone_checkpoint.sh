#!/usr/bin/env bash
# Run checkpoint after completing a milestone
#
# Usage:
#   milestone_checkpoint.sh <milestone_name> [sprint_id]
#
# Environment variables:
#   SPRINT_STATE_DIR - Directory for sprint state files (default: .sprint-state)
#   TEST_CMD         - Command to run tests (default: make test)
#   LINT_CMD         - Command to run linter (default: make lint)

set -euo pipefail

MILESTONE_NAME="${1:-Unknown Milestone}"
SPRINT_ID="${2:-}"
SPRINT_STATE_DIR="${SPRINT_STATE_DIR:-.sprint-state}"
TEST_CMD="${TEST_CMD:-make test}"
LINT_CMD="${LINT_CMD:-make lint}"

echo "MILESTONE CHECKPOINT: $MILESTONE_NAME"
echo "============================================================"
echo
echo "REMINDER: Tests passing does not mean the feature is working!"
echo "   You MUST verify with real data before marking complete!"
echo

FAILURES=0

# Find current sprint JSON
CURRENT_SPRINT=""
if [[ -d "$SPRINT_STATE_DIR" ]]; then
    if [[ -n "$SPRINT_ID" && -f "$SPRINT_STATE_DIR/sprint_$SPRINT_ID.json" ]]; then
        CURRENT_SPRINT="$SPRINT_STATE_DIR/sprint_$SPRINT_ID.json"
    else
        for f in "$SPRINT_STATE_DIR"/sprint_*.json; do
            if [[ -f "$f" ]]; then
                STATUS=$(grep -o '"status": "[^"]*"' "$f" 2>/dev/null | head -1 | cut -d'"' -f4 || echo "")
                if [[ "$STATUS" == "in_progress" || "$STATUS" == "ready" ]]; then
                    CURRENT_SPRINT="$f"
                    SPRINT_ID=$(basename "$f" .json | sed 's/sprint_//')
                    break
                fi
            fi
        done
    fi
fi

# 1. Run tests
echo "1/4 Running tests..."
if $TEST_CMD > /tmp/milestone_test.log 2>&1; then
    echo "  OK Tests pass"
else
    echo "  FAIL Tests fail"
    echo "  See: /tmp/milestone_test.log"
    FAILURES=$((FAILURES + 1))
fi
echo

# 2. Run linting
echo "2/4 Running linter..."
if $LINT_CMD > /tmp/milestone_lint.log 2>&1; then
    echo "  OK Linting passes"
else
    echo "  FAIL Linting fails"
    echo "  See: /tmp/milestone_lint.log"
    FAILURES=$((FAILURES + 1))
fi
echo

# 3. Show files changed
echo "3/4 Files changed in this milestone..."
git diff --stat HEAD | tail -10 || echo "No changes yet"
echo

# 4. File size check
echo "4/4 Checking file sizes..."
echo "  (Check your project's file size guidelines)"
echo

# Summary
echo "============================================================"
if [[ $FAILURES -eq 0 ]]; then
    echo "Milestone checkpoint PASSED!"
    echo

    # Sprint JSON reminder
    if [[ -n "$CURRENT_SPRINT" ]]; then
        echo "============================================================"
        echo "SPRINT JSON UPDATE REQUIRED"
        echo "============================================================"
        echo
        echo "Sprint: $SPRINT_ID"
        echo "File:   $CURRENT_SPRINT"
        echo
        # Check for linked GitHub issues
        if command -v jq &> /dev/null; then
            GITHUB_ISSUES=$(jq -r '.github_issues // [] | map("#" + tostring) | join(", ")' "$CURRENT_SPRINT" 2>/dev/null || echo "")
            if [[ -n "$GITHUB_ISSUES" ]]; then
                echo "Linked GitHub issues: $GITHUB_ISSUES"
                echo "   Include 'Refs $GITHUB_ISSUES' in commit messages"
                echo
            fi
        fi
        echo "Current milestone status:"
        if command -v jq &> /dev/null; then
            jq -r '.features[] | "  \(.id): passes=\(.passes // "null"), completed=\(.completed // "null")"' "$CURRENT_SPRINT" 2>/dev/null || echo "  (could not parse JSON)"
        fi
        echo
        echo "After completing $MILESTONE_NAME:"
        echo "   1. Update passes: true/false in the JSON"
        echo "   2. Set completed: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        echo "   3. Add notes about what was done"
        echo
        echo "============================================================"
    fi
    echo
    echo "Ready to proceed to next milestone."
    exit 0
else
    echo "CHECKPOINT FAILED: $FAILURES verification(s) failed"
    echo "DO NOT mark this milestone as complete!"
    echo "============================================================"
    exit 1
fi
