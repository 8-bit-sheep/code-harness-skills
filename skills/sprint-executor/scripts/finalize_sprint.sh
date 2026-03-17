#!/bin/bash
# finalize_sprint.sh - Finalize a completed sprint
# Moves design docs from planned/ to implemented/<version>/
# Updates sprint JSON status to "completed"
#
# Environment variables:
#   SPRINT_STATE_DIR - Directory for sprint state files (default: .sprint-state)
#   DESIGN_DOCS_DIR  - Root directory for design documents (default: design_docs)

set -e

SPRINT_ID="${1:-}"
TARGET_VERSION="${2:-}"
SPRINT_STATE_DIR="${SPRINT_STATE_DIR:-.sprint-state}"
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-design_docs}"

if [ -z "$SPRINT_ID" ]; then
    echo "Usage: $0 <sprint-id> [target-version]"
    echo ""
    echo "Example: $0 M-FEATURE v1_2_0"
    exit 1
fi

SPRINT_FILE="${SPRINT_STATE_DIR}/sprint_${SPRINT_ID}.json"

if [ ! -f "$SPRINT_FILE" ]; then
    echo "Error: Sprint file not found: $SPRINT_FILE"
    exit 1
fi

echo "================================================================"
echo " Finalizing Sprint: $SPRINT_ID"
echo "================================================================"
echo ""

# Check if all milestones pass
ALL_PASS=$(jq -r '.features | map(select(.passes != true)) | length' "$SPRINT_FILE")
if [ "$ALL_PASS" != "0" ]; then
    echo "Warning: Not all milestones have passes=true"
    jq -r '.features[] | select(.passes != true) | "  - \(.id): passes=\(.passes)"' "$SPRINT_FILE"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Get design doc path from sprint JSON
DESIGN_DOC=$(jq -r '.design_doc // empty' "$SPRINT_FILE")
SPRINT_PLAN=$(jq -r '.sprint_plan // empty' "$SPRINT_FILE")

# Determine target version
if [ -z "$TARGET_VERSION" ]; then
    TARGET_VERSION=$(echo "$DESIGN_DOC" | grep -oE 'v[0-9]+_[0-9]+(_[0-9]+)?' | head -1)
    if [ -z "$TARGET_VERSION" ]; then
        echo "Error: Could not determine target version from design doc path"
        echo "Please specify target version as second argument"
        exit 1
    fi
fi

echo "Target version: $TARGET_VERSION"
echo ""

# Create implemented directory if needed
IMPL_DIR="${DESIGN_DOCS_DIR}/implemented/$TARGET_VERSION"
mkdir -p "$IMPL_DIR"

# Move design doc if it exists in planned/
MOVED_FILES=()

if [ -n "$DESIGN_DOC" ] && [ -f "$DESIGN_DOC" ]; then
    BASENAME=$(basename "$DESIGN_DOC")
    DEST="$IMPL_DIR/$BASENAME"

    if [ -f "$DEST" ]; then
        echo "Design doc already exists at: $DEST"
    else
        echo "Moving design doc:"
        echo "  From: $DESIGN_DOC"
        echo "  To:   $DEST"
        mv "$DESIGN_DOC" "$DEST"
        MOVED_FILES+=("$DESIGN_DOC -> $DEST")

        if grep -q "^\*\*Status\*\*:" "$DEST"; then
            sed -i.bak 's/^\*\*Status\*\*:.*$/\*\*Status\*\*: IMPLEMENTED/' "$DEST"
            rm -f "${DEST}.bak"
            echo "  Updated status to IMPLEMENTED"
        fi
    fi
fi

# Move sprint plan if it exists
if [ -n "$SPRINT_PLAN" ] && [ -f "$SPRINT_PLAN" ]; then
    BASENAME=$(basename "$SPRINT_PLAN")
    DEST="$IMPL_DIR/$BASENAME"

    if [ ! -f "$DEST" ]; then
        echo "Moving sprint plan:"
        echo "  From: $SPRINT_PLAN"
        echo "  To:   $DEST"
        mv "$SPRINT_PLAN" "$DEST"
        MOVED_FILES+=("$SPRINT_PLAN -> $DEST")
    fi
fi

# Update sprint JSON status
echo ""
echo "Updating sprint JSON status to 'completed'..."
TEMP_FILE=$(mktemp)
jq '.status = "completed" | .completed = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))' "$SPRINT_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$SPRINT_FILE"

# Update paths in JSON
if [ ${#MOVED_FILES[@]} -gt 0 ]; then
    TEMP_FILE=$(mktemp)
    NEW_DESIGN_DOC="$IMPL_DIR/$(basename "$DESIGN_DOC" 2>/dev/null || echo "")"
    NEW_SPRINT_PLAN="$IMPL_DIR/$(basename "$SPRINT_PLAN" 2>/dev/null || echo "")"

    jq --arg dd "$NEW_DESIGN_DOC" --arg sp "$NEW_SPRINT_PLAN" '
        if .design_doc then .design_doc = $dd else . end |
        if .sprint_plan then .sprint_plan = $sp else . end
    ' "$SPRINT_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$SPRINT_FILE"
    echo "Updated file paths in sprint JSON"
fi

# Get linked GitHub issues
GITHUB_ISSUES=$(jq -r '.github_issues // [] | map("#" + tostring) | join(", ")' "$SPRINT_FILE" 2>/dev/null || echo "")

echo ""
echo "================================================================"
echo " Sprint Finalized Successfully!"
echo "================================================================"
echo ""
echo "Summary:"
echo "  Sprint ID: $SPRINT_ID"
echo "  Status: completed"
echo "  Target version: $TARGET_VERSION"
if [ -n "$GITHUB_ISSUES" ]; then
    echo "  Linked issues: $GITHUB_ISSUES"
fi
echo ""
echo "Next steps:"
echo "  1. Commit the changes"
echo "  2. Update CHANGELOG if not already done"
echo "  3. Consider creating a release if milestone reached"
