# Long-Running Agent Patterns

**Patterns for building skills that span multiple Claude Code sessions.**

Based on [Anthropic's article on effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).

## Overview

Long-running work (sprints, releases, complex tasks) may span hours or days across multiple Claude Code sessions. These patterns enable **multi-session continuity** with no loss of context.

## Two-Phase Pattern: Initializer + Coding Agent

### Initializer Skill

**Role**: Sets up infrastructure for execution

**Responsibilities:**
- Creates structured JSON progress file
- Sets up session resumption scripts
- Sends handoff message with correlation ID
- Prepares workspace for execution

**Example**: `sprint-planner` skill

### Coding Agent Skill

**Role**: Works incrementally across sessions

**Responsibilities:**
- ALWAYS starts with session_start.sh script
- Reads JSON progress file
- Updates only specific fields (constrained modification)
- Commits progress after each unit of work
- Can pause/resume at any time

**Example**: `sprint-executor` skill

## Key Components

### 1. Session Startup Script

**Purpose**: Restore full context at the start of each session

**Template**: `scripts/session_start.sh <task_id>`

**What it does:**
- Checks pwd (working directory)
- Reads JSON progress file
- Reviews recent git commits (last 3)
- Runs tests to verify clean state
- Shows "Here's where we left off" summary
  - What's complete
  - What's in progress
  - What's pending
  - Current metrics (velocity, LOC, etc.)

**When to use:** ALWAYS at the start of EVERY session continuing work.

**Example from sprint-executor:**
```bash
#!/bin/bash
# Check pwd
echo "Working directory: $(pwd)"

# Load JSON progress
PROGRESS_FILE=".sprint-state/sprint_${SPRINT_ID}.json"
jq '.' "$PROGRESS_FILE"

# Show feature progress
COMPLETE=$(jq '[.features[] | select(.passes == true)] | length' "$PROGRESS_FILE")
TOTAL=$(jq '.features | length' "$PROGRESS_FILE")
echo "Progress: $COMPLETE/$TOTAL features complete"

# Review git log
git log --oneline -3

# Validate tests
make test || echo "⚠️ Tests failing"
```

### 2. JSON Progress File

**Purpose**: Machine-readable state for resumption

**Location**: `.task-state/<task_id>.json` (or project-specific state directory)

**Schema principles:**
- **Constrained modification**: Only specific fields can change during execution
- **Clear state enum**: `not_started`, `in_progress`, `paused`, `completed`, `failed`
- **Timestamps**: Track when work started/updated/completed
- **Correlation ID**: Link to related messages

**Example schema:**
```json
{
  "task_id": "sprint_M-S1",
  "created": "2025-01-27T10:00:00Z",
  "last_updated": "2025-01-27T14:30:00Z",
  "correlation_id": "sprint_M-S1",
  "status": "in_progress",
  "features": [
    {
      "id": "feature_1",
      "description": "Parser foundation",
      "estimated_loc": 200,
      "actual_loc": 214,
      "passes": true,  // ← Only this field changes!
      "started": "2025-01-27T10:30:00Z",
      "completed": "2025-01-27T14:30:00Z"
    },
    {
      "id": "feature_2",
      "description": "Type integration",
      "estimated_loc": 150,
      "actual_loc": null,
      "passes": null,  // ← Still working on this
      "started": "2025-01-27T14:45:00Z",
      "completed": null
    }
  ],
  "metrics": {
    "target_per_day": 200,
    "actual_per_day": 107,
    "progress_percentage": 33
  }
}
```

**Constrained modification pattern:**
- ✅ **Allowed**: Update `passes`, `actual_loc`, `completed`, `notes`
- ❌ **Forbidden**: Change `description`, `estimated_loc`, `acceptance_criteria`
- **Why**: Prevents accidental requirement changes, keeps goals stable

### 3. Correlation IDs

**Purpose**: Track related messages across agent handoffs

**Format**: `<workflow>_<identifier>`

**Examples:**
- `sprint_M-S1` - All messages for sprint M-S1
- `release_v0.4.6` - All messages for v0.4.6 release
- `design_M-DX10` - All messages for design doc M-DX10

**Message format:**
```json
{
  "message_id": "msg_20251127_103045_abc123",
  "correlation_id": "sprint_M-S1",
  "reply_to": "msg_20251127_100000_def456",
  "from": "sprint-executor",
  "to": "user",
  "type": "milestone_complete",
  "payload": { ... }
}
```

**Benefits:**
- Track entire workflow: design-doc → sprint-plan → execution
- Filter messages by workflow
- Debug multi-agent interactions
- Resume work from exact point

### 4. End-to-End Testing

**Purpose**: Test as users would, not just unit tests

**Template**: `scripts/acceptance_test.sh <milestone_id> <test_type>`

**Test types:**
- `parser` - Run example files through parser
- `builtin` - Test builtin functions in REPL
- `examples` - Run specific example files
- `repl` - Interactive REPL testing (manual)
- `e2e` - Full pipeline test (parse → elaborate → type → evaluate)

**Why it matters:**
From the article: "Testing as an actual user would—rather than relying solely on unit tests—catches bugs invisible in code review."

## Workflow Diagram

```
Session 1 (Monday):
  initializer-skill → creates JSON progress file
    └─ JSON: .task-state/task_<id>.json
    └─ Message: correlation_id="workflow_<id>"

Session 2 (Tuesday):
  coding-agent-skill → runs session_start.sh
    └─ Reads JSON: "Feature 1 pending, 0/5 complete"
    └─ Implements features 1-2
    └─ Updates JSON: features 1-2 passes=true
    └─ User says "pause for today"

Session 3 (Wednesday):
  coding-agent-skill → runs session_start.sh
    └─ Reads JSON: "Features 1-2 ✓, Feature 3 pending"
    └─ Continues from Feature 3
    └─ Completes all features
    └─ Sends completion message
```

## Implementation Checklist

**For Initializer Skills:**
- [ ] Create JSON progress file with clear schema
- [ ] Set correlation_id in progress file
- [ ] Send handoff message with correlation_id
- [ ] Include task_id, estimated metrics, features list
- [ ] Document which fields can be modified

**For Coding Agent Skills:**
- [ ] Create session_start.sh script (always run first!)
- [ ] Read JSON progress file at session start
- [ ] Update only allowed fields (constrained modification)
- [ ] Commit progress after each unit of work
- [ ] Support pause/resume at any milestone
- [ ] Send messages with correlation_id

**For Both:**
- [ ] Document multi-session behavior in SKILL.md
- [ ] Create resource file with JSON schema
- [ ] Test resumption across sessions
- [ ] Handle interrupted/failed states gracefully

## Example Workflows

### Sprint Workflow

**Initializer: sprint-planner**
- Analyzes design docs, calculates velocity
- Creates `.sprint-state/sprint_<id>.json`
- Creates `scripts/create_sprint_json.sh`
- Sends `plan_ready` message with `correlation_id: "sprint_<id>"`

**Coding Agent: sprint-executor**
- ALWAYS runs `session_start.sh <sprint-id>` first
- Reads JSON, shows "Here's where we left off"
- Updates `passes` field as milestones complete
- Can pause after any milestone
- Next session resumes from exact point

### Release Workflow

**Initializer: release-manager**
- Creates `.release-state/release_<version>.json`
- Tracks steps: validation, tagging, CI, verification

**Coding Agent: post-release**
- Checks for existing release state
- Resumes from last completed step

## Best Practices

1. **Session startup is mandatory**: ALWAYS run session_start.sh for continuing work
2. **JSON is authoritative**: Markdown is for humans, JSON is source of truth
3. **Constrained modifications**: Only update fields designed to change
4. **Correlation IDs everywhere**: Link all related messages
5. **Test resumption**: Actually test pausing and resuming across sessions
6. **Clear state enums**: Use standard states (not_started, in_progress, paused, completed, failed)
7. **Timestamps**: Track when work happens for metrics and debugging

## Anti-Patterns to Avoid

❌ **No session startup routine**: Agent starts with no context each session
❌ **Markdown-only progress**: Hard to parse, easy to corrupt
❌ **No correlation IDs**: Can't track workflows across handoffs
❌ **Unit tests only**: Integration issues slip through
❌ **Silent state changes**: Unclear what can/can't be modified
❌ **No pause points**: Work must finish in one session or lose progress
❌ **Implicit resumption**: Unclear how to continue work across sessions

## Resources

- Anthropic article: [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- Example: `.claude/skills/sprint-executor/resources/json_progress_schema.md`
- Example: `.claude/skills/agent-inbox/resources/message_format.md`
- Example: `.claude/skills/sprint-executor/scripts/session_start.sh`
