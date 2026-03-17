#!/usr/bin/env bash
# Find GitHub issues that can be closed with this release
#
# Usage: collect_closable_issues.sh <version> [--close] [--json]
#
# Environment variables:
#   GITHUB_REPO     - GitHub repository (default: auto-detected)
#   CHANGELOG_PATH  - Path to changelog (default: CHANGELOG.md)
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version> [--close] [--json]" >&2
    exit 1
fi

VERSION="$1"
shift

DO_CLOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --close) DO_CLOSE=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

CHANGELOG_PATH="${CHANGELOG_PATH:-CHANGELOG.md}"
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-design_docs}"
VERSION_FOLDER="v$(echo "$VERSION" | tr '.' '_')"

# Auto-detect repo
if [[ -z "${GITHUB_REPO:-}" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' | sed 's|\.git$||' || echo "")
fi

echo "Scanning for closable issues (v$VERSION)..." >&2

# Find issue references in commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
    COMMIT_ISSUES=$(git log "$LAST_TAG"..HEAD --pretty=format:"%s %b" 2>/dev/null | grep -oE '(Fixes|Closes|Resolves) #[0-9]+' | grep -oE '[0-9]+' | sort -u || echo "")
else
    COMMIT_ISSUES=""
fi

# Find issue references in CHANGELOG
CHANGELOG_ISSUES=$(grep -oE '#[0-9]+' "$CHANGELOG_PATH" 2>/dev/null | tr -d '#' | sort -u || echo "")

# Find issue references in implemented design docs
DOC_ISSUES=""
if [[ -d "$DESIGN_DOCS_DIR/implemented/$VERSION_FOLDER" ]]; then
    DOC_ISSUES=$(grep -roE '#[0-9]+' "$DESIGN_DOCS_DIR/implemented/$VERSION_FOLDER/" 2>/dev/null | grep -oE '[0-9]+' | sort -u || echo "")
fi

# Combine and deduplicate
ALL_ISSUES=$(echo -e "$COMMIT_ISSUES\n$CHANGELOG_ISSUES\n$DOC_ISSUES" | grep -v '^$' | sort -un)

if [[ -z "$ALL_ISSUES" ]]; then
    echo "No issue references found." >&2
    exit 0
fi

# Check which are still open
for issue_num in $ALL_ISSUES; do
    STATE=$(gh issue view "$issue_num" --json state --jq '.state' 2>/dev/null || echo "UNKNOWN")
    if [[ "$STATE" == "OPEN" ]]; then
        TITLE=$(gh issue view "$issue_num" --json title --jq '.title' 2>/dev/null || echo "Unknown")

        if $JSON_OUTPUT; then
            echo "{\"number\":$issue_num,\"title\":\"$TITLE\"}"
        else
            echo "  #$issue_num: $TITLE"
        fi

        if $DO_CLOSE; then
            COMMENT="This issue has been addressed in v$VERSION."
            if [[ -n "$GITHUB_REPO" ]]; then
                COMMENT="Fixed in [v$VERSION](https://github.com/$GITHUB_REPO/releases/tag/v$VERSION)."
            fi
            gh issue close "$issue_num" --comment "$COMMENT" 2>/dev/null && echo "    -> Closed" >&2 || echo "    -> Failed to close" >&2
        fi
    fi
done

if ! $DO_CLOSE && ! $JSON_OUTPUT; then
    echo "" >&2
    echo "To close these issues: $0 $VERSION --close" >&2
fi
