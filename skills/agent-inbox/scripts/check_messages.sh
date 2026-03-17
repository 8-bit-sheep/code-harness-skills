#!/usr/bin/env bash
# check_messages.sh - Check inbox for messages from agents
#
# Usage:
#   bash .claude/skills/agent-inbox/scripts/check_messages.sh
#
# This script checks for unread messages from autonomous agents
# and displays them with formatted output.
#
# Configuration:
#   INBOX_CMD      - Command that lists messages as JSON (required)
#                    Example: "myproject messages list --unread --json"
#   INBOX_READ_CMD - Command to read a single message (optional)
#                    Example: "myproject messages read"
#   INBOX_ACK_CMD  - Command to acknowledge messages (optional)
#                    Example: "myproject messages ack"
#
# If INBOX_CMD is not set, the script falls back to reading from
# a JSON file at INBOX_FILE (default: .state/inbox/unread.json)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration with defaults
INBOX_CMD="${INBOX_CMD:-}"
INBOX_READ_CMD="${INBOX_READ_CMD:-}"
INBOX_ACK_CMD="${INBOX_ACK_CMD:-}"
INBOX_FILE="${INBOX_FILE:-.state/inbox/unread.json}"

# Get unread messages as JSON
get_messages() {
    if [ -n "$INBOX_CMD" ]; then
        # Use CLI command
        $INBOX_CMD 2>/dev/null || echo "[]"
    elif [ -f "$INBOX_FILE" ]; then
        # Fall back to file-based inbox
        cat "$INBOX_FILE" 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
}

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not found${NC}"
    echo "Install with: brew install jq  (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Get unread messages
MSG_JSON=$(get_messages)
MSG_COUNT=$(echo "$MSG_JSON" | jq 'length' 2>/dev/null || echo "0")

if [ "$MSG_COUNT" -eq 0 ]; then
    echo -e "${GREEN}No unread messages from agents${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}=======================================================${NC}"
printf "${YELLOW}  INBOX: %-2s unread message(s) from agents              ${NC}\n" "$MSG_COUNT"
echo -e "${YELLOW}=======================================================${NC}"
echo ""

# Display each message
MSG_NUM=0
echo "$MSG_JSON" | jq -c '.[]' | while read -r MSG; do
    MSG_NUM=$((MSG_NUM + 1))

    # Extract metadata (field names may vary by implementation)
    MSG_ID=$(echo "$MSG" | jq -r '.message_id // .id // "unknown"')
    FROM_AGENT=$(echo "$MSG" | jq -r '.from_agent // .from // "unknown"')
    TITLE=$(echo "$MSG" | jq -r '.title // .subject // "No title"')
    CREATED_AT=$(echo "$MSG" | jq -r '.created_at // .timestamp // "unknown"')
    CATEGORY=$(echo "$MSG" | jq -r '.category // .type // ""')
    GITHUB_ISSUE=$(echo "$MSG" | jq -r '.github_issue_number // .github_issue // ""')

    echo -e "${BLUE}Message $MSG_NUM${NC}"
    echo -e "  ${BLUE}ID:${NC} $MSG_ID"
    echo -e "  ${BLUE}From:${NC} $FROM_AGENT"
    echo -e "  ${BLUE}Title:${NC} $TITLE"
    echo -e "  ${BLUE}Time:${NC} $CREATED_AT"

    if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "null" ]; then
        echo -e "  ${BLUE}Category:${NC} $CATEGORY"
    fi

    if [ -n "$GITHUB_ISSUE" ] && [ "$GITHUB_ISSUE" != "null" ]; then
        echo -e "  ${BLUE}GitHub Issue:${NC} #$GITHUB_ISSUE"
    fi

    echo ""
done

echo -e "${GREEN}Next steps:${NC}"
if [ -n "$INBOX_READ_CMD" ]; then
    echo "  1. Read full message:"
    echo "     $INBOX_READ_CMD MSG_ID"
fi
if [ -n "$INBOX_ACK_CMD" ]; then
    echo "  2. Acknowledge after processing:"
    echo "     $INBOX_ACK_CMD MSG_ID"
    echo "     $INBOX_ACK_CMD --all"
else
    echo "  1. Read and process each message"
    echo "  2. Mark as read/acknowledged in your inbox backend"
fi
echo ""
