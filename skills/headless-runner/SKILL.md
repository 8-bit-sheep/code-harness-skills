---
name: Headless Runner
description: Run Claude Code in headless/programmatic mode for automation, CI/CD, and agent workflows. Use when user asks about headless mode, programmatic execution, scripting Claude, or automating Claude workflows.
---

# Headless Runner

Run Claude Code programmatically from scripts, CI/CD pipelines, and autonomous agent workflows. Headless mode automatically loads all project configuration (`.claude/` directory), giving you full access to skills, agents, hooks, and commands.

## Quick Start

**Most common usage:**
```bash
# Basic headless invocation (from project directory)
claude -p "Your prompt here"

# With JSON output for programmatic parsing
claude -p "Run the test suite" --output-format json

# Control tool access
claude -p "Analyze failures" --allowedTools "Bash,Read,Grep"

# Multi-turn conversation
claude -p "Start task" --output-format json > result.json
SESSION_ID=$(jq -r '.session_id' result.json)
claude --resume $SESSION_ID "Continue with next step"
```

**What gets loaded automatically:**
- `.claude/settings.json` and `.claude/settings.local.json`
- `.claude/agents/` (all project agents)
- `.claude/skills/` (all project skills)
- Hooks configured in settings
- Slash commands from `.claude/commands/`
- CLAUDE.md project instructions

## When to Use This Skill

Invoke this skill when user asks about:
- "How do I run Claude headless?"
- "Can I automate Claude workflows?"
- "How to use Claude in CI/CD?"
- "Programmatic Claude execution"
- "Script Claude commands"
- "Agent-to-agent communication"
- "Scheduled Claude tasks"

## Core Commands

### Basic Invocation

```bash
# Text output (default)
claude -p "Prompt here"

# JSON output with metadata
claude -p "Prompt here" --output-format json
# Returns: {session_id, result, cost, duration, ...}

# Streaming JSON (for long-running tasks)
claude -p "Prompt here" --output-format stream-json
```

### Tool Permissions

```bash
# Allow specific tools
claude -p "Task" --allowedTools "Bash,Read,Write"

# Allow all tools (use with caution)
claude -p "Task" --allowedTools "*"

# Permission mode for edits
claude -p "Task" --permission-mode acceptEdits
```

### Multi-Turn Conversations

```bash
# Resume specific session
claude --resume SESSION_ID "Continue task"

# Continue most recent session
claude --continue "Next instruction"

# Extract session ID from JSON output
SESSION_ID=$(claude -p "Start" --output-format json | jq -r '.session_id')
claude --resume $SESSION_ID "Continue"
```

## Common Use Cases

### 1. CI/CD Integration

```bash
# .github/workflows/automated-task.yml
- name: Run automated analysis
  run: |
    claude -p "Analyze test failures and suggest fixes" \
      --output-format json \
      --allowedTools "Bash,Read,Grep" \
      > result.json

- name: Check for issues
  run: |
    STATUS=$(jq -r '.status' result.json)
    if [ "$STATUS" != "success" ]; then
      echo "::error::Analysis failed"
      exit 1
    fi
```

### 2. Scheduled Analysis

```bash
#!/bin/bash
# cron_daily_check.sh - Run via cron daily

cd /path/to/project

# Run analysis
claude -p "Check for code quality issues" \
  --output-format json > analysis.json

# If issues found, notify
ISSUES=$(jq -r '.issueCount' analysis.json)
if [ "$ISSUES" -gt 0 ]; then
  echo "Found $ISSUES code quality issues"
fi
```

### 3. Agent-to-Agent Workflows

```bash
#!/bin/bash
# autonomous_workflow.sh

# Agent A: Create design doc
claude -p "Use design-doc-creator to document feature X" \
  --output-format json > design.json
DESIGN_DOC=$(jq -r '.artifactPath' design.json)

# Agent B: Plan sprint from design
claude -p "Use sprint-planner to create plan from $DESIGN_DOC" \
  --output-format json > plan.json
PLAN_FILE=$(jq -r '.planPath' plan.json)

# Agent C: Execute sprint
claude -p "Use sprint-executor to execute $PLAN_FILE" \
  --output-format json > execution.json
```

### 4. Automated Testing

```bash
#!/bin/bash
# test_quality.sh

# Run tests with analysis
claude -p "Run test suite and analyze any failures" \
  --output-format json > results.json

# Parse results
SUCCESS_RATE=$(jq -r '.successRate' results.json)

# Assert quality threshold
if (( $(echo "$SUCCESS_RATE < 0.75" | bc -l) )); then
  echo "Quality below threshold: $SUCCESS_RATE"
  exit 1
fi
```

## Available Scripts

### `scripts/test_headless.sh`
Test headless mode works correctly with project configuration.

**What it tests:**
- `claude` command is available
- Project configuration loads (.claude/ directory)
- Skills are accessible
- Agents are accessible
- JSON output parses correctly
- Multi-turn sessions work

### `scripts/run_with_retry.sh <prompt> [max_retries]`
Run headless command with automatic retry on failure.

**Features:**
- Retries on transient failures
- Exponential backoff
- JSON output preserved
- Exit codes: 0 (success), 1 (permanent failure), 2 (retries exhausted)

## Workflow Patterns

### Pattern 1: Single Command
**Use for:** Simple, one-off tasks
```bash
claude -p "Generate changelog from git log since last tag"
```

### Pattern 2: Sequential Pipeline
**Use for:** Multi-step workflows where each step depends on previous
```bash
#!/bin/bash
set -euo pipefail
claude -p "Step 1" --output-format json > step1.json
ARTIFACT1=$(jq -r '.artifact' step1.json)
claude -p "Step 2 using $ARTIFACT1" --output-format json > step2.json
```

### Pattern 3: Conversation Session
**Use for:** Multi-turn tasks that need context
```bash
RESULT=$(claude -p "Analyze codebase for tech debt" --output-format json)
SESSION_ID=$(echo "$RESULT" | jq -r '.session_id')
claude --resume $SESSION_ID "Focus on files over 800 lines"
claude --resume $SESSION_ID "Generate refactoring plan"
```

### Pattern 4: Parallel Execution
**Use for:** Independent tasks that can run concurrently
```bash
claude -p "Task A" --output-format json > taskA.json &
claude -p "Task B" --output-format json > taskB.json &
wait
jq -s '{taskA: .[0], taskB: .[1]}' taskA.json taskB.json
```

## Quick Tips

**Output formats:**
- `--output-format text` (default) - Human-readable
- `--output-format json` - For automation (includes session_id, status, cost)
- `--output-format stream-json` - For real-time progress

**Error handling:**
- Always check exit codes: `if ! claude -p "..." ; then ...`
- Validate JSON: `echo "$RESULT" | jq -e '.status == "success"'`
- Use retry with backoff (see `run_with_retry.sh` script)

**Tool permissions:**
- Analysis: `--allowedTools "Read,Grep,Glob"`
- Testing: `--allowedTools "Bash,Read"`
- Development: `--allowedTools "Bash,Read,Write,Edit"`

## Resources

### CLI Reference
See [`resources/cli_reference.md`](resources/cli_reference.md) for complete CLI flag documentation.

### Examples
See [`resources/examples.md`](resources/examples.md) for comprehensive workflow examples.

### Troubleshooting
See [`resources/troubleshooting.md`](resources/troubleshooting.md) for common issues and solutions.

## Notes

- **Requires**: Claude Code CLI installed and in PATH
- **Context window**: Be mindful of token limits for large prompts
- **Costs**: Track with `--output-format json` -> `.cost` field
- **Concurrency**: Multiple headless sessions can run in parallel
- **State**: Each invocation is stateless unless using `--resume`
