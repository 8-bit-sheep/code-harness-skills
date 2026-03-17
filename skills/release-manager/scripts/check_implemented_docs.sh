#!/usr/bin/env bash
# Verify all implemented design docs are documented in CHANGELOG
#
# Usage: check_implemented_docs.sh <version>
#
# Environment variables:
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)
#   CHANGELOG_PATH  - Path to changelog (default: CHANGELOG.md)

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <version>" >&2
    echo "Example: $0 1.2.0" >&2
    exit 1
fi

VERSION="$1"
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-design_docs}"
CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.md}"

# Convert version to folder format (1.2.0 -> v1_2_0)
VERSION_FOLDER="v$(echo "$VERSION" | tr '.' '_')"

IMPL_DIR="$DESIGN_DOCS_DIR/implemented/$VERSION_FOLDER"

if [[ ! -d "$IMPL_DIR" ]]; then
    echo "No implemented docs directory found: $IMPL_DIR"
    echo "Nothing to check."
    exit 0
fi

echo "Checking implemented docs in $IMPL_DIR against CHANGELOG..."
echo

MISSING=0
TOTAL=0

for doc in "$IMPL_DIR"/*.md; do
    [[ ! -f "$doc" ]] && continue

    BASENAME=$(basename "$doc" .md)

    # Skip sprint plans and analysis docs
    if echo "$BASENAME" | grep -qiE '(sprint-plan|analysis|retro)'; then
        continue
    fi

    TOTAL=$((TOTAL + 1))

    # Check if feature is mentioned in CHANGELOG
    if grep -qi "$BASENAME" "$CHANGELOG_PATH" 2>/dev/null; then
        echo "  OK $BASENAME - found in CHANGELOG"
    else
        echo "  MISSING $BASENAME - NOT in CHANGELOG"
        MISSING=$((MISSING + 1))
    fi
done

echo
echo "Total feature docs: $TOTAL"
echo "Missing from CHANGELOG: $MISSING"

if [[ $MISSING -gt 0 ]]; then
    echo
    echo "Add entries for missing docs to CHANGELOG before releasing."
    exit 1
else
    echo "All feature docs are in CHANGELOG."
    exit 0
fi
