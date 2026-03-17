#!/usr/bin/env bash
# Close a GitHub issue with proper release references
#
# Usage: close_issues_with_references.sh <version> <issue> [section]
#
# Environment variables:
#   GITHUB_REPO     - GitHub repository (default: auto-detected)
#   CHANGELOG_PATH  - Path to changelog (default: CHANGELOG.md)
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <version> <issue> [section]" >&2
    exit 1
fi

VERSION="$1"
ISSUE="$2"
SECTION="${3:-}"

CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.md}"
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-design_docs}"
VERSION_FOLDER="v$(echo "$VERSION" | tr '.' '_')"

if [[ -z "${GITHUB_REPO:-}" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' | sed 's|\.git$||' || echo "")
fi

RELEASE_URL=""
if [[ -n "$GITHUB_REPO" ]]; then
    RELEASE_URL="https://github.com/$GITHUB_REPO/releases/tag/v$VERSION"
fi

# Build closing comment
COMMENT="Fixed in [v$VERSION]($RELEASE_URL)."

# Find related design doc
DESIGN_DOC=$(grep -rl "#$ISSUE" "$DESIGN_DOCS_DIR/implemented/$VERSION_FOLDER/" 2>/dev/null | head -1 || echo "")
if [[ -n "$DESIGN_DOC" ]]; then
    COMMENT="$COMMENT\n\nDesign doc: \`$DESIGN_DOC\`"
fi

echo "Closing issue #$ISSUE with comment:"
echo -e "$COMMENT"
echo ""

read -p "Proceed? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh issue close "$ISSUE" --comment "$(echo -e "$COMMENT")"
    echo "Closed #$ISSUE"
else
    echo "Cancelled."
fi
