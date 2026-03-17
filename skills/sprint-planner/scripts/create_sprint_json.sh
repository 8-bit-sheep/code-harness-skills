#!/bin/bash
#
# Create Sprint JSON Progress File
#
# Purpose: Generate structured JSON progress file from sprint plan
# Based on: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
#
# Usage:
#   scripts/create_sprint_json.sh <sprint_id> <sprint_plan_md> [design_doc_md]
#
# Environment variables:
#   SPRINT_STATE_DIR - Directory for sprint state files (default: .sprint-state)
#   DESIGN_DOCS_DIR  - Root directory for design documents (default: design_docs)
#
# This script implements the "Initializer" pattern from the Anthropic article:
# - Creates structured JSON with feature list
# - Only `passes` field should be modified during execution
# - Enables multi-session continuity

set -e  # Exit on error

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <sprint_id> <sprint_plan_md> [design_doc_md]"
    echo "Example: $0 M-S1 design_docs/planned/v2_0/m-s1-sprint-plan.md design_docs/planned/v2_0/m-s1-feature.md"
    exit 1
fi

SPRINT_ID="$1"
SPRINT_PLAN="$2"
DESIGN_DOC="${3:-}"

# Output file
PROGRESS_DIR="${SPRINT_STATE_DIR:-.sprint-state}"
PROGRESS_FILE="${PROGRESS_DIR}/sprint_${SPRINT_ID}.json"

# Create state directory if it doesn't exist
mkdir -p "$PROGRESS_DIR"

# Check if sprint plan exists
if [ ! -f "$SPRINT_PLAN" ]; then
    echo "Error: Sprint plan not found: $SPRINT_PLAN"
    exit 1
fi

# Check if design doc exists (if provided)
if [ -n "$DESIGN_DOC" ] && [ ! -f "$DESIGN_DOC" ]; then
    echo "Warning: Design doc not found: $DESIGN_DOC"
    DESIGN_DOC=""
fi

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================================"
echo " Creating Sprint JSON Progress File"
echo "================================================================"
echo ""
echo "Sprint ID: $SPRINT_ID"
echo "Sprint Plan: $SPRINT_PLAN"
if [ -n "$DESIGN_DOC" ]; then
    echo "Design Doc: $DESIGN_DOC"
fi
echo "Output: $PROGRESS_FILE"
echo ""

# Check if file already exists
if [ -f "$PROGRESS_FILE" ]; then
    echo "Warning: Progress file already exists: $PROGRESS_FILE"
    echo ""
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Extract milestones from sprint plan markdown
echo "Parsing sprint plan..."

extract_milestones() {
    local plan_file="$1"

    python3 - "$plan_file" << 'PYEOF'
import re, sys, json

plan_file = sys.argv[1]
with open(plan_file) as f:
    content = f.read()

# Split into milestone sections: ### M1: Title (~NNN LOC)
sections = re.split(r'(?=^### M\d)', content, flags=re.MULTILINE)

milestones = []
for section in sections:
    heading_match = re.match(r'^### (M\d+)[:\s]+(.+?)(?:\s*\(.*?~(\d+)\s*LOC.*?\))?\s*$', section, re.MULTILINE)
    if not heading_match:
        continue

    milestone_id = heading_match.group(1).strip()
    description = heading_match.group(2).strip()
    description = re.sub(r'\s*\(~\d+\s*(hours?|LOC).*\)\s*$', '', description)
    estimated_loc = int(heading_match.group(3)) if heading_match.group(3) else 0

    criteria = []
    for line in section.split('\n'):
        m = re.match(r'^\s*-\s*\[\s*\]\s*(.+)$', line)
        if m:
            criteria.append(m.group(1).strip())

    deps = []
    dep_match = re.search(r'\*\*Dependencies[:\*]*\s*(.+)', section)
    if dep_match:
        dep_text = dep_match.group(1).strip()
        if dep_text.lower() not in ('none', 'n/a', '-'):
            deps = re.findall(r'M\d+', dep_text)

    milestones.append({
        "id": milestone_id + "_" + re.sub(r'[^A-Z0-9]+', '_', description.upper()).strip('_')[:30],
        "description": description,
        "estimated_loc": estimated_loc,
        "dependencies": deps,
        "acceptance_criteria": criteria if criteria else ["Acceptance criteria not parsed - fill manually"],
        "passes": None,
        "started": None,
        "completed": None,
        "notes": None
    })

if not milestones:
    milestones = [{
        "id": "MILESTONE_ID",
        "description": "Milestone description (auto-parse failed - fill manually)",
        "estimated_loc": 0,
        "dependencies": [],
        "acceptance_criteria": ["Criterion 1", "Criterion 2"],
        "passes": None,
        "started": None,
        "completed": None,
        "notes": None
    }]

print(json.dumps(milestones, indent=2))
PYEOF
}

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract velocity estimates from sprint plan
ESTIMATED_TOTAL_LOC=$(grep -iE '(total|estimated).*\b[0-9]+\b' "$SPRINT_PLAN" 2>/dev/null | grep -oE '\b[0-9]{2,}\b' | tail -1 || echo "")
ESTIMATED_TOTAL_LOC=${ESTIMATED_TOTAL_LOC:-1000}

ESTIMATED_DAYS=$(grep -iE '(duration|estimated).*\b[0-9]+\b.*day' "$SPRINT_PLAN" 2>/dev/null | grep -oE '\b[0-9]+\b' | head -1 || echo "")
ESTIMATED_DAYS=${ESTIMATED_DAYS:-7}

TARGET_LOC_PER_DAY=$((ESTIMATED_TOTAL_LOC / ESTIMATED_DAYS))

# Extract milestones into temp file
MILESTONES_TMPFILE=$(mktemp)
extract_milestones "$SPRINT_PLAN" > "$MILESTONES_TMPFILE"
MILESTONE_COUNT=$(python3 -c "import json; print(len(json.load(open('$MILESTONES_TMPFILE'))))" 2>/dev/null || echo "0")

if [ "$MILESTONE_COUNT" -gt 1 ]; then
    echo -e "${GREEN}Parsed ${MILESTONE_COUNT} milestones from sprint plan${NC}"
else
    echo "Could not auto-parse milestones (found ${MILESTONE_COUNT}). Template created - fill manually."
fi

# Create JSON structure
python3 - "$SPRINT_ID" "$TIMESTAMP" "$ESTIMATED_DAYS" "$DESIGN_DOC" "$SPRINT_PLAN" "$ESTIMATED_TOTAL_LOC" "$TARGET_LOC_PER_DAY" "$PROGRESS_FILE" "$MILESTONES_TMPFILE" << 'PYEOF2'
import json, sys

sprint_id = sys.argv[1]
timestamp = sys.argv[2]
estimated_days = int(sys.argv[3])
design_doc = sys.argv[4]
sprint_plan = sys.argv[5]
estimated_total_loc = int(sys.argv[6])
target_loc_per_day = int(sys.argv[7])
output_file = sys.argv[8]
milestones_file = sys.argv[9]

with open(milestones_file) as f:
    milestones = json.load(f)

data = {
    "sprint_id": sprint_id,
    "status": "not_started",
    "created": timestamp,
    "design_doc": design_doc,
    "sprint_plan": sprint_plan,
    "github_issues": [],
    "velocity": {
        "target_loc_per_day": target_loc_per_day,
        "estimated_total_loc": estimated_total_loc,
        "estimated_days": estimated_days
    },
    "features": milestones
}

with open(output_file, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF2

# Clean up temp file
rm -f "$MILESTONES_TMPFILE"

echo -e "${GREEN}Created JSON progress file${NC}"
echo ""

# Validate JSON
if jq -e . "$PROGRESS_FILE" >/dev/null 2>&1; then
    echo -e "${GREEN}JSON validation passed${NC}"
else
    echo "JSON validation failed!"
    echo "Please check $PROGRESS_FILE for syntax errors"
    exit 1
fi

# Try to extract GitHub issue numbers from design doc
echo ""
echo "Discovering linked GitHub issues..."

DISCOVERED_ISSUES=""

# Extract explicit #123 references from design doc
if [ -n "$DESIGN_DOC" ] && [ -f "$DESIGN_DOC" ]; then
    EXPLICIT_REFS=$(grep -oE '#[0-9]+' "$DESIGN_DOC" 2>/dev/null | tr -d '#' | sort -u || echo "")
    for issue_num in $EXPLICIT_REFS; do
        if ! echo "$DISCOVERED_ISSUES" | grep -qw "$issue_num"; then
            DISCOVERED_ISSUES="${DISCOVERED_ISSUES} ${issue_num}"
            echo -e "${GREEN}  Found #${issue_num} from explicit reference${NC}"
        fi
    done
fi

# Deduplicate and format
GITHUB_ISSUES=$(echo "$DISCOVERED_ISSUES" | tr ' ' '\n' | grep -v '^$' | sort -un | tr '\n' ',' | sed 's/,$//')

if [ -n "$GITHUB_ISSUES" ]; then
    TEMP_FILE=$(mktemp)
    jq --argjson issues "[$GITHUB_ISSUES]" '.github_issues = $issues' "$PROGRESS_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$PROGRESS_FILE"
    echo -e "${GREEN}  Added github_issues: [${GITHUB_ISSUES}] to sprint JSON${NC}"
else
    echo "  No related GitHub issues found"
fi

echo ""
echo "================================================================"
echo " Next Steps"
echo "================================================================"
echo ""
echo "1. Edit the JSON file to fill in actual milestone details:"
echo "   ${PROGRESS_FILE}"
echo ""
echo "2. If this sprint addresses a GitHub issue, ensure github_issues is set:"
echo "   jq '.github_issues = [123, 456]' ${PROGRESS_FILE} > tmp && mv tmp ${PROGRESS_FILE}"
echo ""
echo "3. Start sprint execution:"
echo "   Use sprint-executor skill to begin implementing milestones"
echo ""
echo "================================================================"

exit 0
