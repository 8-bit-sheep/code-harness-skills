# Agent Inbox Command Reference

Complete reference for agent inbox operations. These describe the logical operations any inbox implementation should support. Adapt the syntax to your project's CLI or API.

## Operation Overview

| Operation | Purpose |
|-----------|---------|
| `list` | List messages |
| `read` | Read full message |
| `ack` | Mark as read |
| `unack` | Mark as unread |
| `send` | Send message |
| `search` | Search messages |
| `reply` | Reply to GitHub issue |
| `import-github` | Import from GitHub |
| `watch` | Watch for new messages |
| `cleanup` | Remove old messages |

## List Messages

```
inbox list [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--unread` | Only unread messages | false |
| `--inbox NAME` | Filter by inbox | all |
| `--from AGENT` | Filter by sender | all |
| `--limit N` | Max messages | 20 |
| `--json` | JSON output | false |

**Examples:**
```bash
inbox list --unread
inbox list --inbox user --limit 10
inbox list --from code-reviewer --json
```

## Read Message

```
inbox read MSG_ID [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--peek` | Don't mark as read | false |
| `--json` | JSON output | false |

**Examples:**
```bash
inbox read msg_20251210_123456_abc123
inbox read msg_20251210_123456_abc123 --peek
```

## Acknowledge Message

```
inbox ack [MSG_ID] [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--all` | Mark all as read | false |
| `--inbox NAME` | Filter for --all | all |

**Examples:**
```bash
inbox ack msg_20251210_123456_abc123
inbox ack --all
inbox ack --all --inbox user
```

## Un-acknowledge Message

```
inbox unack MSG_ID
```

Moves message back to unread status.

## Send Message

```
inbox send INBOX "MESSAGE" [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--title TEXT` | Message title | truncated message |
| `--from AGENT` | Sender name | "cli" |
| `--correlation ID` | Correlation ID | none |
| `--github` | Create GitHub issue | false |
| `--type TYPE` | Category (bug/feature/general) | none |
| `--repo OWNER/REPO` | GitHub repo | config default |

**Examples:**
```bash
# Basic local message
inbox send user "Task complete" --title "Done" --from "agent"

# Bug report synced to GitHub
inbox send user "Build crashes on ARM" \
  --title "Build bug" --type bug --github

# Feature request synced to GitHub
inbox send user "Need async support" \
  --title "Async" --type feature --github
```

## Search Messages

```
inbox search "QUERY" [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--inbox NAME` | Filter by inbox | all |
| `--limit N` | Maximum results | 20 |
| `--json` | JSON output | false |

**Examples:**
```bash
inbox search "parser error"
inbox search "type inference" --limit 5
```

## Reply to GitHub Issue

```
inbox reply MSG_ID "REPLY_TEXT" [flags]
```

Adds a comment to an existing GitHub issue thread. Only works for messages that were created with `--github` flag.

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--from AGENT` | Sender name for attribution | "cli" |
| `--repo OWNER/REPO` | Override repo | message's repo or config default |

## Import from GitHub

```
inbox import-github [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--repo OWNER/REPO` | GitHub repo | config default |
| `--labels LIST` | Comma-separated labels | config watch_labels |
| `--inbox NAME` | Target inbox | "user" |
| `--dry-run` | Preview only | false |

## Watch Messages

```
inbox watch [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--inbox NAME` | Watch specific inbox | all |

## Cleanup Messages

```
inbox cleanup [flags]
```

**Flags:**
| Flag | Description | Default |
|------|-------------|---------|
| `--older-than DURATION` | Remove older than (e.g., 7d) | required |
| `--expired` | Remove expired only | false |
| `--dry-run` | Preview only | false |

## Database Schema (SQLite Backend)

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

## GitHub Configuration

In your project config file:

```yaml
github:
  expected_user: YourGitHubUsername   # REQUIRED for GitHub sync
  default_repo: owner/repo           # Default repo for issues
  create_labels:                     # Added to created issues
    - agent-message
  watch_labels:                      # Filter for import
    - agent-message
  auto_import: true                  # Auto-import on session start
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Database/storage error |
| 4 | GitHub error |
