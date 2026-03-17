#!/usr/bin/env bash
# Find issues that have been implemented and can be closed
#
# Usage: find_closable.sh [--close] [--dry-run] [--json]
#
# Environment variables:
#   GITHUB_REPO     - GitHub repository (default: auto-detected)
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)
#   CHANGELOG_PATH  - Path to changelog (default: CHANGELOG.md)

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

DO_CLOSE=false
DRY_RUN=false
JSON_OUTPUT=false
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-${PROJECT_ROOT}/design_docs}"
CHANGELOG_PATH="${CHANGELOG_PATH:-${PROJECT_ROOT}/CHANGELOG.md}"

if [[ -z "${GITHUB_REPO:-}" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' | sed 's|\.git$||' || echo "")
fi
REPO="${GITHUB_REPO}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --close) DO_CLOSE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

cd "$PROJECT_ROOT"

"$SCRIPT_DIR/check_auth.sh" --quiet || exit 1

ISSUES=$(gh issue list --repo "$REPO" --state open --limit 100 --json number,title,labels,url 2>/dev/null || echo "[]")

if [[ "$ISSUES" == "[]" ]]; then
    echo "No open issues found."
    exit 0
fi

TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

echo "Finding Closable Issues" >&2
echo "=======================" >&2
echo "" >&2

echo "$ISSUES" | jq -c '.[]' | while read -r issue; do
    NUMBER=$(echo "$issue" | jq -r '.number')
    TITLE=$(echo "$issue" | jq -r '.title')
    URL=$(echo "$issue" | jq -r '.url')

    CLOSABLE=false
    REASON=""
    DOC=""

    # Check 1: Referenced in implemented design docs
    FOUND=$(grep -rl "#$NUMBER" "$DESIGN_DOCS_DIR/implemented/" 2>/dev/null | head -1 || echo "")
    if [[ -n "$FOUND" ]]; then
        CLOSABLE=true; REASON="design_doc_implemented"; DOC="$FOUND"
    fi

    # Check 2: Referenced in CHANGELOG
    if ! $CLOSABLE && grep -qE "#$NUMBER\b" "$CHANGELOG_PATH" 2>/dev/null; then
        CLOSABLE=true; REASON="in_changelog"
    fi

    # Check 3: M-ID match in implemented docs
    if ! $CLOSABLE; then
        M_ID=$(echo "$TITLE" | grep -oE "M-[A-Z0-9-]+" | head -1 || echo "")
        if [[ -n "$M_ID" ]]; then
            M_ID_LOWER=$(echo "$M_ID" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
            FOUND=$(find "$DESIGN_DOCS_DIR/implemented/" -name "*${M_ID_LOWER}*" 2>/dev/null | head -1 || echo "")
            if [[ -n "$FOUND" ]]; then
                CLOSABLE=true; REASON="m_id_implemented"; DOC="$FOUND"
            fi
        fi
    fi

    if $CLOSABLE; then
        if $JSON_OUTPUT; then
            echo "{\"number\":$NUMBER,\"title\":\"$TITLE\",\"reason\":\"$REASON\",\"doc\":\"$DOC\"}"
        else
            echo "Issue #$NUMBER: $TITLE"
            echo "  Reason: $REASON"
            [[ -n "$DOC" ]] && echo "  Doc: $DOC"
            echo ""
        fi
        echo "$NUMBER|$TITLE|$REASON|$DOC" >> "$TMPFILE"
    fi
done

if ! $JSON_OUTPUT; then
    CLOSABLE_COUNT=$(wc -l < "$TMPFILE" | tr -d ' ')
    echo "Found $CLOSABLE_COUNT closable issue(s)" >&2
fi

if $DO_CLOSE || $DRY_RUN; then
    while IFS='|' read -r num title reason doc; do
        [[ -z "$num" ]] && continue
        COMMENT="This issue has been addressed."
        case "$reason" in
            design_doc_implemented) COMMENT="$COMMENT Implemented via design doc: \`$doc\`" ;;
            in_changelog) COMMENT="$COMMENT Referenced in CHANGELOG." ;;
            m_id_implemented) COMMENT="$COMMENT Implemented in: \`$doc\`" ;;
        esac

        if $DRY_RUN; then
            echo "[DRY RUN] Would close #$num: $title" >&2
        elif $DO_CLOSE; then
            echo "Closing #$num: $title" >&2
            gh issue close "$num" --repo "$REPO" --comment "$COMMENT" 2>/dev/null && echo "  Closed." >&2 || echo "  FAILED." >&2
        fi
    done < "$TMPFILE"
fi

if [[ -s "$TMPFILE" ]] && ! $DO_CLOSE && ! $DRY_RUN && ! $JSON_OUTPUT; then
    echo "" >&2
    echo "To close these issues: $0 --close" >&2
    echo "To preview: $0 --dry-run" >&2
fi
