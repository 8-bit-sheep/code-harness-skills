#!/usr/bin/env bash
set -euo pipefail

# Create a new design document in ${DESIGN_DOCS_DIR}/planned/
#
# Usage: create_planned_doc.sh <doc-name> [version]
#
# Environment variables:
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)
#   VERSION_FILE    - Path to version file (default: VERSION)
#   CHANGELOG_PATH  - Path to changelog (default: CHANGELOG.md)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-${PROJECT_ROOT}/design_docs}"
VERSION_FILE="${VERSION_FILE:-${PROJECT_ROOT}/VERSION}"
CHANGELOG_PATH="${CHANGELOG_PATH:-${PROJECT_ROOT}/CHANGELOG.md}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get current version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE" | tr -d '[:space:]'
        return
    fi
    if [ -f "$CHANGELOG_PATH" ]; then
        grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' "$CHANGELOG_PATH" | sort -V | tail -1
        return
    fi
    echo "unknown"
}

get_next_version_folder() {
    local current="$1"
    local version="${current#v}"
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)
    local next_patch=$((patch + 1))
    echo "v${major}_${minor}_${next_patch}"
}

CURRENT_VERSION=$(get_current_version)
NEXT_VERSION_FOLDER=$(get_next_version_folder "$CURRENT_VERSION")

if [ $# -lt 1 ]; then
    echo -e "${RED}Error: Missing required argument${NC}"
    echo ""
    echo -e "${CYAN}Current version: $CURRENT_VERSION${NC}"
    echo -e "${CYAN}Suggested next version: $NEXT_VERSION_FOLDER${NC}"
    echo ""
    echo "Usage: create_planned_doc.sh <doc-name> [version]"
    echo ""
    echo "Examples:"
    echo "  create_planned_doc.sh m-dx2-better-errors"
    echo "  create_planned_doc.sh reflection-system $NEXT_VERSION_FOLDER"
    exit 1
fi

DOC_NAME="$1"
VERSION="${2:-}"

# Determine target directory
if [ -n "$VERSION" ]; then
    TARGET_DIR="$DESIGN_DOCS_DIR/planned/$VERSION"
    mkdir -p "$TARGET_DIR"
else
    TARGET_DIR="$DESIGN_DOCS_DIR/planned"
    mkdir -p "$TARGET_DIR"
fi

DOC_PATH="$TARGET_DIR/${DOC_NAME}.md"

# Check if document already exists
if [ -f "$DOC_PATH" ]; then
    echo -e "${YELLOW}Warning: Document already exists at $DOC_PATH${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

CURRENT_DATE=$(date +%Y-%m-%d)

# Create document from template
cat > "$DOC_PATH" << 'EOF'
# [Feature Name]

**Status**: Planned
**Target**: [Version, e.g., v1.2.0]
**Priority**: [P0/P1/P2 - High/Medium/Low]
**Estimated**: [Time estimate, e.g., 2 days]
**Dependencies**: [None or list other features]

## Problem Statement

[What problem does this solve? Why is it needed?]

**Current State:**
- [Describe current pain points]
- [Include metrics if available]

**Impact:**
- [Who is affected?]
- [How significant is the problem?]

## Goals

**Primary Goal:** [Main objective in one sentence]

**Success Metrics:**
- [Measurable outcome 1]
- [Measurable outcome 2]
- [Measurable outcome 3]

## Solution Design

### Overview

[High-level description of the solution]

### Architecture

[Describe the technical approach]

**Components:**
1. **Component 1**: [Description]
2. **Component 2**: [Description]
3. **Component 3**: [Description]

### Implementation Plan

**Phase 1: [Name]** (~X hours)
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

**Phase 2: [Name]** (~X hours)
- [ ] Task 1
- [ ] Task 2

### Files to Modify/Create

**New files:**
- `path/to/new_file` - [Purpose, ~XXX LOC]

**Modified files:**
- `path/to/existing_file` - [Changes needed, ~XXX LOC]

## Examples

### Example 1: [Use Case]

**Before:**
```
[Code or workflow before the change]
```

**After:**
```
[Code or workflow after the change]
```

## Success Criteria

- [ ] Criterion 1 (with acceptance test)
- [ ] Criterion 2 (with acceptance test)
- [ ] All tests passing
- [ ] Documentation updated

## Testing Strategy

**Unit tests:**
- [What to test]

**Integration tests:**
- [What to test]

## Non-Goals

**Not in this feature:**
- [Thing 1] - [Why deferred]
- [Thing 2] - [Why out of scope]

## Timeline

**Week 1** (X hours):
- Phase 1 implementation

**Total: ~X hours across Y weeks**

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| [Risk 1] | [High/Med/Low] | [How to address] |

## References

- [Link to related design docs]
- [Link to issues or discussions]

## Future Work

[Features that build on this but are out of scope for now]

---

**Document created**: CURRENT_DATE_PLACEHOLDER
**Last updated**: CURRENT_DATE_PLACEHOLDER
EOF

# Replace date placeholder
sed -i.bak "s/CURRENT_DATE_PLACEHOLDER/$CURRENT_DATE/g" "$DOC_PATH"
rm -f "${DOC_PATH}.bak"

RELATIVE_PATH="${DOC_PATH#$PROJECT_ROOT/}"

echo -e "${GREEN}Created design document:${NC}"
echo "  $DOC_PATH"
echo ""
echo -e "${CYAN}Version context:${NC}"
echo "  Current: $CURRENT_VERSION"
echo "  Next version: $NEXT_VERSION_FOLDER"
if [ -n "$VERSION" ]; then
    echo "  Doc target: $VERSION"
fi
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Edit $DOC_PATH to fill in the template"
echo "  2. Replace [placeholders] with actual content"
echo "  3. Commit when ready: git add $DOC_PATH"
echo ""
echo "---"
echo "DESIGN_DOC_PATH: $RELATIVE_PATH"
