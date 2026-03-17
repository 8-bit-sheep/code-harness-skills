#!/usr/bin/env bash
# List all open GitHub issues with details
#
# Usage: list_open_issues.sh [--json] [--labels LABELS] [--limit N] [--repo OWNER/REPO]
#
# Environment variables:
#   GITHUB_REPO - GitHub repository (default: auto-detected from git remote)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

JSON_OUTPUT=false
LABELS=""
LIMIT=100

# Auto-detect repo
if [[ -z "${GITHUB_REPO:-}" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' | sed 's|\.git$||' || echo "")
fi
REPO="${GITHUB_REPO}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) JSON_OUTPUT=true; shift ;;
        --labels) LABELS="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --repo) REPO="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

"$SCRIPT_DIR/check_auth.sh" --quiet || exit 1

GH_ARGS="--repo $REPO --state open --limit $LIMIT"
if [[ -n "$LABELS" ]]; then
    GH_ARGS="$GH_ARGS --label $LABELS"
fi

if $JSON_OUTPUT; then
    gh issue list $GH_ARGS --json number,title,labels,createdAt,updatedAt,assignees,author,url
else
    echo "Open Issues for $REPO"
    echo "=================================================="
    echo ""

    ISSUES=$(gh issue list $GH_ARGS --json number,title,labels,createdAt,updatedAt,assignees 2>/dev/null || echo "[]")

    if [[ "$ISSUES" == "[]" ]]; then
        echo "No open issues found."
        exit 0
    fi

    echo "$ISSUES" | jq -r '.[] |
        "Issue #\(.number): \(.title)\n" +
        "  Labels: \(if .labels | length > 0 then (.labels | map(.name) | join(", ")) else "none" end)\n" +
        "  Created: \(.createdAt | split("T")[0])\n" +
        "  Updated: \(.updatedAt | split("T")[0])\n" +
        "  Assignee: \(if .assignees | length > 0 then (.assignees | map(.login) | join(", ")) else "unassigned" end)\n"'

    echo ""
    echo "Summary"
    echo "-------"
    TOTAL=$(echo "$ISSUES" | jq 'length')
    echo "Total open: $TOTAL"

    BUGS=$(echo "$ISSUES" | jq '[.[] | select(.labels[]?.name == "bug")] | length')
    echo "Bugs: $BUGS"

    ENHANCEMENTS=$(echo "$ISSUES" | jq '[.[] | select(.labels[]?.name == "enhancement")] | length')
    echo "Enhancements: $ENHANCEMENTS"
fi
