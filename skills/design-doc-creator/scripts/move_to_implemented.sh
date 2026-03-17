#!/usr/bin/env bash
set -euo pipefail

# Move a design document from planned/ to implemented/
#
# Usage: move_to_implemented.sh <doc-name> <version>
#
# Environment variables:
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-${PROJECT_ROOT}/design_docs}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    echo ""
    echo "Usage: move_to_implemented.sh <doc-name> <version>"
    echo ""
    echo "Examples:"
    echo "  move_to_implemented.sh m-dx1-developer-experience v1_0_0"
    exit 1
fi

DOC_NAME="$1"
VERSION="$2"

# Find source document
SOURCE_PATH=""
if [ -f "$DESIGN_DOCS_DIR/planned/${DOC_NAME}.md" ]; then
    SOURCE_PATH="$DESIGN_DOCS_DIR/planned/${DOC_NAME}.md"
else
    FOUND=$(find "$DESIGN_DOCS_DIR/planned" -name "${DOC_NAME}.md" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        SOURCE_PATH="$FOUND"
    else
        echo -e "${RED}Error: Document not found in planned/: ${DOC_NAME}.md${NC}"
        echo ""
        echo "Available docs in planned/:"
        find "$DESIGN_DOCS_DIR/planned" -name "*.md" -type f | sed 's|.*/||' | sort
        exit 1
    fi
fi

TARGET_DIR="$DESIGN_DOCS_DIR/implemented/$VERSION"
mkdir -p "$TARGET_DIR"

TARGET_PATH="$TARGET_DIR/${DOC_NAME}.md"

if [ -f "$TARGET_PATH" ]; then
    echo -e "${YELLOW}Warning: Document already exists in implemented/$VERSION/${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

CURRENT_DATE=$(date +%Y-%m-%d)

cp "$SOURCE_PATH" "$TARGET_PATH"

if grep -q "^\*\*Status\*\*:" "$TARGET_PATH"; then
    sed -i.bak "s/^\*\*Status\*\*:.*/\*\*Status\*\*: Implemented/" "$TARGET_PATH"
    rm "${TARGET_PATH}.bak" 2>/dev/null || true
fi

if grep -q "^\*\*Last updated\*\*:" "$TARGET_PATH"; then
    sed -i.bak "s/^\*\*Last updated\*\*:.*/\*\*Last updated\*\*: $CURRENT_DATE/" "$TARGET_PATH"
    rm "${TARGET_PATH}.bak" 2>/dev/null || true
fi

echo -e "${GREEN}Copied design document to implemented:${NC}"
echo "  From: $SOURCE_PATH"
echo "  To:   $TARGET_PATH"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the document at $TARGET_PATH"
echo "  2. Add implementation report section"
echo "  3. Commit changes: git add $TARGET_PATH"
echo "  4. AFTER committing, delete original:"
echo "     git rm $SOURCE_PATH"
