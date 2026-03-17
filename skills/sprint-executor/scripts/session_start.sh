#!/bin/bash
#
# Session Start Script for Sprint Executor
#
# Purpose: Resume a sprint across multiple sessions
# Based on: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
#
# Usage:
#   scripts/session_start.sh <sprint_id>
#
# Environment variables:
#   SPRINT_STATE_DIR - Directory for sprint state files (default: .sprint-state)
#   TEST_CMD         - Command to run tests (default: make test)

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sprint_id>"
    echo "Example: $0 M-S1"
    exit 1
fi

SPRINT_ID="$1"
SPRINT_STATE_DIR="${SPRINT_STATE_DIR:-.sprint-state}"
PROGRESS_FILE="${SPRINT_STATE_DIR}/sprint_${SPRINT_ID}.json"
TEST_CMD="${TEST_CMD:-make test}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================"
echo " Sprint Continuation Check - ${SPRINT_ID}"
echo "================================================================"
echo ""

# 1. Check working directory
echo -e "${BLUE}1. Working Directory${NC}"
echo "   $(pwd)"
echo ""

# 2. Check if progress file exists
if [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}Progress file not found: $PROGRESS_FILE${NC}"
    echo ""
    echo "Options:"
    echo "  1. If this is a new sprint, run sprint-planner first"
    echo "  2. If continuing an old sprint, check the sprint ID is correct"
    exit 1
fi

echo -e "${GREEN}Found progress file: $PROGRESS_FILE${NC}"
echo ""

# 3. Load sprint metadata
echo -e "${BLUE}2. Sprint Metadata${NC}"
SPRINT_STATUS=$(jq -r '.status' "$PROGRESS_FILE")
CREATED=$(jq -r '.created' "$PROGRESS_FILE")
LAST_SESSION=$(jq -r '.last_session' "$PROGRESS_FILE")
LAST_CHECKPOINT=$(jq -r '.last_checkpoint // "Not set"' "$PROGRESS_FILE")

echo "   Status: $SPRINT_STATUS"
echo "   Created: $CREATED"
echo "   Last session: $LAST_SESSION"
echo "   Last checkpoint: $LAST_CHECKPOINT"
echo ""

# Show linked GitHub issues
GITHUB_ISSUES=$(jq -r '.github_issues // [] | @csv' "$PROGRESS_FILE" 2>/dev/null | tr -d '"')
if [ -n "$GITHUB_ISSUES" ] && [ "$GITHUB_ISSUES" != "" ]; then
    echo -e "${BLUE}   Linked GitHub Issues${NC}"
    for issue_num in $(echo "$GITHUB_ISSUES" | tr ',' ' '); do
        echo "   -> #${issue_num}"
    done
    echo "   Commits: 'refs #...' (link only) or 'Fixes #...' (auto-close)"
    echo ""
fi

# 4. Feature progress summary
echo -e "${BLUE}3. Feature Progress${NC}"
TOTAL_FEATURES=$(jq '.features | length' "$PROGRESS_FILE")
COMPLETE_FEATURES=$(jq '[.features[] | select(.passes == true)] | length' "$PROGRESS_FILE")
FAILED_FEATURES=$(jq '[.features[] | select(.passes == false)] | length' "$PROGRESS_FILE")
IN_PROGRESS=$(jq '[.features[] | select(.passes == null and .started != null)] | length' "$PROGRESS_FILE")
NOT_STARTED=$(jq '[.features[] | select(.started == null)] | length' "$PROGRESS_FILE")

echo "   Total: $TOTAL_FEATURES features"
echo -e "   ${GREEN}Complete: $COMPLETE_FEATURES${NC}"
if [ "$FAILED_FEATURES" -gt 0 ]; then
    echo -e "   ${RED}Failed: $FAILED_FEATURES${NC}"
fi
if [ "$IN_PROGRESS" -gt 0 ]; then
    echo -e "   ${YELLOW}In progress: $IN_PROGRESS${NC}"
fi
if [ "$NOT_STARTED" -gt 0 ]; then
    echo "   Not started: $NOT_STARTED"
fi
echo ""

# Show completed features
if [ "$COMPLETE_FEATURES" -gt 0 ]; then
    echo -e "${GREEN}Completed Features:${NC}"
    jq -r '.features[] | select(.passes == true) | "  \(.id): \(.description) (\(.actual_loc) LOC)"' "$PROGRESS_FILE"
    echo ""
fi

# Show next feature to work on
if [ "$NOT_STARTED" -gt 0 ]; then
    echo -e "${BLUE}Next Feature:${NC}"
    NEXT_FEATURE=$(jq -r '.features[] | select(.started == null) | "  -> \(.id): \(.description) (estimated: \(.estimated_loc) LOC)" | @text' "$PROGRESS_FILE" | head -1)
    if [ -n "$NEXT_FEATURE" ]; then
        echo "$NEXT_FEATURE"
    else
        echo "  -> Check dependencies - some features may be blocked"
    fi
    echo ""
fi

# Velocity metrics
echo -e "${BLUE}4. Velocity Metrics${NC}"
TARGET_LOC=$(jq -r '.velocity.target_loc_per_day' "$PROGRESS_FILE")
ACTUAL_LOC=$(jq -r '.velocity.actual_loc_per_day' "$PROGRESS_FILE")
ESTIMATED_TOTAL=$(jq -r '.velocity.estimated_total_loc' "$PROGRESS_FILE")
ACTUAL_TOTAL=$(jq -r '.velocity.actual_total_loc' "$PROGRESS_FILE")

echo "   Target: ${TARGET_LOC} LOC/day"
echo "   Actual: ${ACTUAL_LOC} LOC/day"
echo "   Progress: ${ACTUAL_TOTAL}/${ESTIMATED_TOTAL} LOC"
echo ""

# Recent git commits
echo -e "${BLUE}5. Recent Work (Last 3 Commits)${NC}"
git log --oneline -3 --color=always | sed 's/^/   /'
echo ""

# Git status
echo -e "${BLUE}6. Working Directory Status${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "   ${YELLOW}Uncommitted changes detected${NC}"
    git status --short | sed 's/^/   /'
else
    echo -e "   ${GREEN}Working directory clean${NC}"
fi
echo ""

# Run tests
echo -e "${BLUE}7. Pre-Session Validation${NC}"
echo "   Running tests..."

if $TEST_CMD 2>&1 | grep -q "FAIL"; then
    echo -e "   ${RED}Tests failing!${NC}"
    echo "   You should fix tests before continuing the sprint."
    exit 1
else
    echo -e "   ${GREEN}All tests pass${NC}"
fi
echo ""

# Summary
echo "================================================================"
echo " Summary"
echo "================================================================"
echo ""

if [ "$SPRINT_STATUS" = "completed" ]; then
    echo -e "${GREEN}This sprint is complete!${NC}"
    echo "Next steps: Review, tag release, move design docs"
elif [ "$SPRINT_STATUS" = "paused" ]; then
    echo -e "${YELLOW}Sprint is paused${NC}"
    echo "Last checkpoint: $LAST_CHECKPOINT"
    echo "To resume: Continue with in-progress features"
elif [ "$SPRINT_STATUS" = "in_progress" ]; then
    echo -e "${BLUE}Sprint in progress${NC}"
    echo "Current progress: $COMPLETE_FEATURES/$TOTAL_FEATURES features complete"
else
    echo -e "${BLUE}Ready to start sprint${NC}"
    echo "Begin with the first feature listed above."
fi

echo ""
echo "Progress file: $PROGRESS_FILE"
echo "================================================================"

exit 0
