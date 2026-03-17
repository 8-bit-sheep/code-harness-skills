#!/usr/bin/env bash
# Match open GitHub issues to design documents
#
# Usage: match_design_docs.sh [--planned] [--implemented] [--all] [--json]
#
# Environment variables:
#   GITHUB_REPO     - GitHub repository (default: auto-detected)
#   DESIGN_DOCS_DIR - Root directory for design docs (default: design_docs)

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

CHECK_PLANNED=true
CHECK_IMPLEMENTED=true
JSON_OUTPUT=false
DESIGN_DOCS_DIR="${DESIGN_DOCS_DIR:-${PROJECT_ROOT}/design_docs}"

if [[ -z "${GITHUB_REPO:-}" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' | sed 's|\.git$||' || echo "")
fi
REPO="${GITHUB_REPO}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --planned) CHECK_PLANNED=true; CHECK_IMPLEMENTED=false; shift ;;
        --implemented) CHECK_PLANNED=false; CHECK_IMPLEMENTED=true; shift ;;
        --all) CHECK_PLANNED=true; CHECK_IMPLEMENTED=true; shift ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

cd "$PROJECT_ROOT"

"$SCRIPT_DIR/check_auth.sh" --quiet || exit 1

ISSUES=$(gh issue list --repo "$REPO" --state open --limit 100 --json number,title,labels 2>/dev/null || echo "[]")

if [[ "$ISSUES" == "[]" ]]; then
    echo "No open issues found."
    exit 0
fi

echo "Matching Issues to Design Docs" >&2
echo "===============================" >&2
echo "" >&2

echo "$ISSUES" | jq -c '.[]' | while read -r issue; do
    NUMBER=$(echo "$issue" | jq -r '.number')
    TITLE=$(echo "$issue" | jq -r '.title')

    MATCH_DOC=""
    MATCH_TYPE=""
    MATCH_STATUS=""

    # Strategy 1: Exact issue number reference
    if $CHECK_PLANNED; then
        FOUND=$(grep -rl "#$NUMBER" "$DESIGN_DOCS_DIR/planned/" 2>/dev/null | head -1 || echo "")
        if [[ -n "$FOUND" ]]; then
            MATCH_DOC="$FOUND"; MATCH_TYPE="exact_reference"; MATCH_STATUS="PLANNED"
        fi
    fi

    if [[ -z "$MATCH_DOC" ]] && $CHECK_IMPLEMENTED; then
        FOUND=$(grep -rl "#$NUMBER" "$DESIGN_DOCS_DIR/implemented/" 2>/dev/null | head -1 || echo "")
        if [[ -n "$FOUND" ]]; then
            MATCH_DOC="$FOUND"; MATCH_TYPE="exact_reference"; MATCH_STATUS="IMPLEMENTED"
        fi
    fi

    # Strategy 2: M-ID patterns
    if [[ -z "$MATCH_DOC" ]]; then
        M_ID=$(echo "$TITLE" | grep -oE "M-[A-Z0-9-]+" | head -1 || echo "")
        if [[ -n "$M_ID" ]]; then
            M_ID_LOWER=$(echo "$M_ID" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
            if $CHECK_PLANNED; then
                FOUND=$(find "$DESIGN_DOCS_DIR/planned/" -name "*${M_ID_LOWER}*" 2>/dev/null | head -1 || echo "")
                if [[ -n "$FOUND" ]]; then
                    MATCH_DOC="$FOUND"; MATCH_TYPE="m_id_match"; MATCH_STATUS="PLANNED"
                fi
            fi
            if [[ -z "$MATCH_DOC" ]] && $CHECK_IMPLEMENTED; then
                FOUND=$(find "$DESIGN_DOCS_DIR/implemented/" -name "*${M_ID_LOWER}*" 2>/dev/null | head -1 || echo "")
                if [[ -n "$FOUND" ]]; then
                    MATCH_DOC="$FOUND"; MATCH_TYPE="m_id_match"; MATCH_STATUS="IMPLEMENTED"
                fi
            fi
        fi
    fi

    # Strategy 3: Keyword matching
    if [[ -z "$MATCH_DOC" ]]; then
        KEYWORDS=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | grep -oE '\b[a-z]{4,}\b' | \
            grep -vE '^(the|and|for|with|this|that|from|have|been|will|are|was|should|when|what|where|which|into|than|them|then|there|these|those|would|could|about|after|before|between|other|over|under|some|such|only|also|just|like|make|well|even|most|more|very)$' | \
            head -5 || echo "")

        for word in $KEYWORDS; do
            if $CHECK_PLANNED && [[ -z "$MATCH_DOC" ]]; then
                FOUND=$(grep -ril "$word" "$DESIGN_DOCS_DIR/planned/" 2>/dev/null | head -1 || echo "")
                if [[ -n "$FOUND" ]]; then
                    for word2 in $KEYWORDS; do
                        if [[ "$word" != "$word2" ]] && grep -qi "$word2" "$FOUND" 2>/dev/null; then
                            MATCH_DOC="$FOUND"; MATCH_TYPE="keyword_match"; MATCH_STATUS="PLANNED"
                            break
                        fi
                    done
                fi
            fi
            [[ -n "$MATCH_DOC" ]] && break
        done
    fi

    # Output
    if $JSON_OUTPUT; then
        if [[ -n "$MATCH_DOC" ]]; then
            echo "{\"number\":$NUMBER,\"title\":\"$TITLE\",\"status\":\"$MATCH_STATUS\",\"doc\":\"$MATCH_DOC\",\"match_type\":\"$MATCH_TYPE\"}"
        else
            echo "{\"number\":$NUMBER,\"title\":\"$TITLE\",\"status\":\"NOT_COVERED\",\"doc\":null,\"match_type\":null}"
        fi
    else
        echo "Issue #$NUMBER: $TITLE"
        if [[ -n "$MATCH_DOC" ]]; then
            echo "  Status: $MATCH_STATUS"
            echo "  Design doc: $MATCH_DOC"
            echo "  Match type: $MATCH_TYPE"
        else
            echo "  Status: NOT COVERED"
            echo "  No matching design doc found"
        fi
        echo ""
    fi
done
