---
name: Agent Inbox
description: Check and process messages from autonomous agents. Use when starting a session, after agent handoffs, or when checking for completion notifications. This skill describes the pattern of inter-agent messaging -- adapt the implementation to your project's tooling.
---

# Agent Inbox

**Check for messages from autonomous agents at session start and process completion notifications.**

## Quick Start

The agent inbox pattern requires a messaging backend. Choose one that fits your project:

| Backend | Best For | Example |
|---------|----------|---------|
| SQLite database | Local multi-agent projects | `messages.db` in project state dir |
| File-based (JSON/JSONL) | Simple setups, easy debugging | `~/.project/inbox/*.json` |
| GitHub Issues | Cross-instance visibility | Issues with agent labels |
| Redis/NATS | Distributed systems | Pub/sub channels |

**Most common usage (with a CLI-based backend):**
```bash
# List all messages
inbox list

# Show only unread messages
inbox list --unread

# Read full message content
inbox read MSG_ID

# Acknowledge (mark as read)
inbox ack MSG_ID
inbox ack --all

# Send a message
inbox send user "Your message" --title "Title" --from "agent-name"

# Send bug/feature to GitHub (for cross-instance visibility)
inbox send user "Bug report" --type bug --github
```

**Expected output (at session start):**
```
AGENT INBOX: 2 unread message(s) from autonomous agents

ID: msg_20251210_143021_abc123
From: sprint-executor
Title: Sprint S1 complete
Time: 2025-12-10T14:30:21Z

ID: msg_20251210_143055_def456
From: code-reviewer
Title: Parser Bug
Time: 2025-12-10T14:30:55Z
```

## When to Use This Skill

**Invoke this skill when:**
- **Session starts** -- First action in every coding session
- **After handoffs** -- When you have sent work to autonomous agents
- **Periodic checks** -- User asks "any updates from agents?"
- **Debugging** -- To see agent communication history

## Configuration

Configure the agent inbox for your project by setting these values in your project configuration (e.g., `config.yaml`, `.env`, or equivalent):

```yaml
# Agent Inbox Configuration
inbox:
  # Backend type: "sqlite", "file", "github", "redis"
  backend: sqlite

  # Path to the message store (for sqlite/file backends)
  # Default: <project_state_dir>/messages.db
  store_path: .state/messages.db

  # Auto-check for messages on session start
  auto_check: true

  # Message retention (how long to keep read messages)
  retention_days: 30

  # GitHub integration (optional)
  github:
    enabled: false
    default_repo: owner/repo
    create_labels:
      - agent-message
    watch_labels:
      - agent-message
    auto_import: true
```

**Environment variables:**
| Variable | Purpose |
|----------|---------|
| `AGENT_INBOX_BACKEND` | Override backend type |
| `AGENT_INBOX_STORE_PATH` | Override store path |
| `AGENT_INBOX_GITHUB_REPO` | Override GitHub repo |

## Storage Backends

### SQLite (Recommended)

Store messages in a SQLite database for reliable local access:

```sql
CREATE TABLE inbox_messages (
    id TEXT PRIMARY KEY,
    message_id TEXT UNIQUE NOT NULL,
    correlation_id TEXT,
    from_agent TEXT NOT NULL,
    to_inbox TEXT NOT NULL,
    message_type TEXT NOT NULL,
    title TEXT NOT NULL,
    payload TEXT,
    category TEXT,
    github_issue_number INTEGER,
    github_repo TEXT,
    status TEXT NOT NULL,       -- unread, read, archived, deleted
    created_at TEXT NOT NULL,
    read_at TEXT,
    expires_at TEXT
);
```

### File-Based

Store messages as JSON files in a directory:

```
.state/inbox/
  msg_20251210_143021_abc123.json
  msg_20251210_143055_def456.json
```

Each file contains a single message in the standard format (see resources/message_format.md).

### GitHub Issues

Use GitHub Issues as a cross-instance message store:
- Agents create issues with specific labels
- Other agents or sessions import issues into their local inbox
- Good for bugs and feature requests that need visibility

## Workflow

### 1. Session Start Check

**At the start of every session, check for unread messages.**

If messages exist:
- Read and summarize each message to the user
- Identify message type (completion, error, handoff)
- Ask user if they want action taken
- Acknowledge after handling

### 2. Process Completion Notifications

**When an agent reports completion:**
```bash
# 1. Read the full message
inbox read MSG_ID

# 2. Review results mentioned in payload
ls -la results/output/

# 3. Report to user
echo "Task complete! Results at: results/output/"

# 4. Acknowledge after processing
inbox ack MSG_ID
```

### 3. Handle Error Reports

**When an agent reports errors:**
```bash
# 1. Read the full error details
inbox read MSG_ID

# 2. Check logs if mentioned
cat .state/logs/agent.log

# 3. Diagnose and report to user
echo "Agent encountered error: Tests failing at step 3/5"

# 4. Either fix manually or send corrective instructions
```

### 4. Respond to Agent or User

```bash
# Send response to an agent
inbox send task-executor "Approved, proceed" \
  --title "Approval" --from "user"

# Send notification to user inbox
inbox send user "Issue resolved" \
  --title "Status update" --from "claude-code"
```

## GitHub Integration (Bi-directional)

### Message Types and Routing

| Type | Purpose | Goes to GitHub? |
|------|---------|-----------------|
| `bug` | Bug report | Yes (with `--github`) |
| `feature` | Feature request | Yes (with `--github`) |
| `general` | Coordination | No (local only) |

**Routing guidance:**
- **Bugs and features** -- Use `--github` for visibility across all instances
- **Coordination messages** -- Local only, for agent-to-agent communication
- **Instructions from humans** -- Create GitHub issues, they will be imported automatically

### Human Instructions via GitHub

You can write instructions as GitHub issues and have agents pick them up:

1. Create issue on GitHub with the configured label (e.g., `agent-message`)
2. Next session, import runs automatically (if `auto_import: true`)
3. Issue appears in agent's inbox as a message
4. Agent reads and acts on the instructions

### GitHub Prerequisites

1. Install GitHub CLI: `brew install gh`
2. Authenticate: `gh auth login`
3. Check account: `gh auth status`

## Correlation IDs

**Messages support correlation IDs for tracking handoff chains:**

```json
{
  "message_id": "msg_20251210_103045_abc123",
  "correlation_id": "task_T-42",
  "from_agent": "task-executor",
  "to_inbox": "user",
  "title": "Task complete",
  "payload": "All steps complete"
}
```

**Benefits:**
- Track entire workflow: design -> plan -> execution
- Filter messages by workflow
- Debug multi-agent interactions
- Resume work from where you left off

**For complete specification**, see [`resources/message_format.md`](resources/message_format.md)

## Message Types (Payloads)

### Completion Notification
```json
{
  "type": "task_complete",
  "correlation_id": "task_T-42",
  "payload": {
    "task_id": "T-42",
    "steps_complete": 5,
    "result": "All tests passing"
  }
}
```

### Error Report
```json
{
  "type": "error",
  "correlation_id": "task_T-42",
  "payload": {
    "error": "Tests failing: 5 checks broken",
    "details": ".state/logs/executor.log"
  }
}
```

### Handoff Instruction
```json
{
  "type": "handoff",
  "correlation_id": "task_T-42",
  "payload": {
    "task_id": "T-42",
    "artifact_path": "docs/planned/task-plan.md",
    "action_requested": "execute_plan"
  }
}
```

## Available Scripts

### `scripts/check_messages.sh`

Check for unread messages and display them with formatted output.

**Usage:**
```bash
.claude/skills/agent-inbox/scripts/check_messages.sh
```

Requires `jq` and a CLI tool that outputs messages as JSON. Configure the `INBOX_CMD` variable in the script or set it via environment.

## Resources

### Message Format Reference
See [`resources/message_format.md`](resources/message_format.md) for complete message format specification.

## Command Reference

These are the logical operations any inbox backend should support:

| Operation | Purpose |
|-----------|---------|
| `list` | View all messages |
| `list --unread` | View only unread |
| `read MSG_ID` | View full message |
| `ack MSG_ID` | Mark as read |
| `ack --all` | Mark all as read |
| `unack MSG_ID` | Mark as unread |
| `send INBOX "msg"` | Send message |
| `search "query"` | Search messages |
| `import-github` | Import from GitHub |
| `cleanup` | Remove old messages |

## Notes

- **Session start check is critical** -- Messages from overnight agents can contain important results or errors
- **Message lifecycle**: Unread -> Read -> Archived (optional)
- **GitHub sync**: Optional, for bugs/features that need cross-instance visibility
- **Correlation IDs**: Always include them for traceability in multi-agent workflows
