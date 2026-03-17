#!/bin/bash
#
# Validate Sprint JSON Progress File
#
# Purpose: Ensure sprint JSON has real milestones before execution begins
#
# Usage:
#   scripts/validate_sprint_json.sh <sprint_id>
#
# Environment variables:
#   SPRINT_STATE_DIR - Directory for sprint state files (default: .sprint-state)
#
# Exit codes:
#   0 - Valid JSON with real milestones
#   1 - Invalid JSON or placeholder data detected

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ $# -lt 1 ]; then
    echo "Usage: $0 <sprint_id>"
    exit 1
fi

SPRINT_ID="$1"
SPRINT_STATE_DIR="${SPRINT_STATE_DIR:-.sprint-state}"
PROGRESS_FILE="${SPRINT_STATE_DIR}/sprint_${SPRINT_ID}.json"

echo "================================================================"
echo " Validating Sprint JSON: ${SPRINT_ID}"
echo "================================================================"
echo ""

if [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}ERROR: Sprint JSON not found: ${PROGRESS_FILE}${NC}"
    echo "sprint-planner must create the JSON file first."
    exit 1
fi

echo "File: ${PROGRESS_FILE}"
echo ""

ERRORS=0

# Validate JSON syntax
if ! jq -e . "$PROGRESS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Invalid JSON syntax${NC}"
    exit 1
fi
echo -e "${GREEN}JSON syntax valid${NC}"

# Check for placeholder milestone ID
if jq -e '.features[] | select(.id == "MILESTONE_ID")' "$PROGRESS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Found placeholder milestone ID 'MILESTONE_ID'${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}No placeholder milestone IDs${NC}"
fi

# Check for placeholder acceptance criteria
if jq -e '.features[].acceptance_criteria[] | select(. == "Criterion 1" or . == "Criterion 2")' "$PROGRESS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Found placeholder acceptance criteria${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}No placeholder acceptance criteria${NC}"
fi

# Check minimum milestone count
MILESTONE_COUNT=$(jq '.features | length' "$PROGRESS_FILE")
if [ "$MILESTONE_COUNT" -lt 2 ]; then
    echo -e "${RED}ERROR: Only ${MILESTONE_COUNT} milestone(s) defined (minimum: 2)${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}${MILESTONE_COUNT} milestones defined${NC}"
fi

# Check estimated LOC is reasonable
TOTAL_LOC=$(jq '.velocity.estimated_total_loc' "$PROGRESS_FILE")
if [ "$TOTAL_LOC" -eq 1000 ]; then
    echo -e "${YELLOW}WARNING: estimated_total_loc is default value (1000)${NC}"
fi

# Check for GitHub issues (informational)
GITHUB_ISSUES=$(jq -r '.github_issues // [] | length' "$PROGRESS_FILE")
if [ "$GITHUB_ISSUES" -gt 0 ]; then
    echo -e "${GREEN}${GITHUB_ISSUES} GitHub issue(s) linked${NC}"
else
    echo -e "${YELLOW}No GitHub issues linked to this sprint${NC}"
fi

# Check each milestone has required fields
INCOMPLETE_MILESTONES=$(jq -r '.features[] | select(.description == "Milestone description" or .estimated_loc == 0) | .id' "$PROGRESS_FILE")
if [ -n "$INCOMPLETE_MILESTONES" ]; then
    echo -e "${RED}ERROR: Milestones with default/placeholder values:${NC}"
    echo "$INCOMPLETE_MILESTONES"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}All milestones have custom values${NC}"
fi

echo ""
echo "================================================================"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}VALIDATION FAILED: ${ERRORS} error(s) found${NC}"
    echo "sprint-planner must populate the JSON with real milestone data."
    echo "================================================================"
    exit 1
else
    echo -e "${GREEN}VALIDATION PASSED: Sprint JSON is ready for execution${NC}"
    echo "================================================================"
    exit 0
fi
