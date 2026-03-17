---
name: Sprint Executor
description: Execute approved sprint plans with test-driven development, continuous linting, progress tracking, and pause points. Supports parallel milestone execution via Task sub-agents. Use when user says "execute sprint", "start sprint", or wants to implement an approved sprint plan.
---

# Sprint Executor

Execute an approved sprint plan with continuous progress tracking, testing, and documentation updates. Supports **parallel execution** of independent milestones using Task sub-agents for faster sprints.

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `SPRINT_STATE_DIR` | `.sprint-state` | Directory for sprint JSON progress files |
| `DESIGN_DOCS_DIR` | `design_docs` | Root directory for design documents |
| `BUILD_CMD` | `make build` | Command to build the project |
| `TEST_CMD` | `make test` | Command to run tests |
| `LINT_CMD` | `make lint` | Command to run linting |
| `FMT_CMD` | `make fmt` | Command to auto-format code |
| `CHANGELOG_PATH` | `CHANGELOG.md` | Path to changelog file |

## Quick Start

**Sequential execution (default):**
```bash
# User says: "Execute the sprint plan in design_docs/planned/M-S1.md"
# This skill will:
# 1. Validate prerequisites (tests pass, linting clean)
# 2. Create TodoWrite tasks for all milestones
# 3. Execute each milestone with test-driven development
# 4. Run checkpoint after each milestone (tests + lint)
# 5. Update CHANGELOG and sprint plan progressively
# 6. Pause after each milestone for user review
```

**Parallel execution (for independent milestones):**
```bash
# User says: "Execute sprint plan at docs/sprint-plans/M-FOO.md in parallel"
# This skill will:
# 1. Read sprint plan and identify all milestones
# 2. Analyze dependencies - group independent milestones for parallel execution
# 3. Spawn Task sub-agents per milestone (branch, TDD, implement, commit)
# 4. Act as integration agent - merge branches, run full test suite
# 5. Write sprint retrospective with timing and friction analysis
```

## When to Use This Skill

Invoke this skill when:
- User says "execute sprint", "start sprint", "begin implementation"
- User has an approved sprint plan ready to implement
- User wants guided execution with built-in quality checks
- User needs progress tracking and pause points

**Choose parallel mode when:**
- Sprint has 3+ milestones with independent work
- Milestones touch different files/packages (low merge conflict risk)

**Choose sequential mode when:**
- Milestones have strict dependencies (M2 depends on M1's output)
- All milestones touch the same files
- Sprint is small (1-2 milestones)

## Core Principles

1. **Test-Driven**: All code must pass tests before moving to next milestone
2. **Lint-Clean**: All code must pass linting before moving to next milestone
3. **Document as You Go**: Update CHANGELOG and sprint plan progressively
4. **Pause for Breath**: Stop at natural breakpoints for review and approval
5. **Track Everything**: Use TodoWrite to maintain visible progress
6. **Parallelize When Possible**: Independent milestones run as concurrent Task sub-agents for speed
7. **Failing Tests First**: Sub-agents MUST write failing tests before implementation

## Multi-Session Continuity

**Sprint execution can span multiple sessions!**

Based on [Anthropic's long-running agent patterns](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), sprint-executor implements the "Coding Agent" pattern:

- **Session Startup Routine**: Every session starts with `session_start.sh`
  - Checks working directory
  - Reads JSON progress file (`${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json`)
  - Reviews recent git commits
  - Validates tests pass
  - Prints "Here's where we left off" summary

- **Structured Progress Tracking**: JSON file tracks state
  - Features with `passes: true/false/null` (follows "constrained modification" pattern)
  - Velocity metrics updated automatically
  - Clear checkpoint messages
  - Session timestamps

- **Pause and Resume**: Work can be interrupted at any time
  - Status saved to JSON: `not_started`, `in_progress`, `paused`, `completed`
  - Next session picks up exactly where you left off

**For JSON schema details**, see [`resources/json_progress_schema.md`](resources/json_progress_schema.md)

## Available Scripts

### `scripts/session_start.sh <sprint_id>`
Resume sprint execution across multiple sessions.

**When to use:** ALWAYS at the start of EVERY session continuing a sprint.

**What it does:**
1. Loads sprint JSON progress file
2. Shows linked GitHub issues
3. Displays feature progress summary
4. Shows velocity metrics
5. Runs tests to verify clean state
6. Prints "Here's where we left off" summary

### `scripts/validate_prerequisites.sh`
Validate prerequisites before starting sprint execution.

**What it checks:**
1. Working directory status (clean/uncommitted changes)
2. Current branch
3. Test suite passes
4. Linting passes

### `scripts/validate_sprint_json.sh <sprint_id>`
**REQUIRED before starting any sprint.** Validates that sprint JSON has real milestones (not placeholders).

### `scripts/milestone_checkpoint.sh <milestone_name> [sprint_id]`
Run checkpoint after completing a milestone.

**CRITICAL: Tests passing does not mean the feature is working!** This script verifies with REAL DATA.

**What it does:**
1. Runs `${TEST_CMD}` and `${LINT_CMD}`
2. Shows git diff of changed files
3. Checks file sizes
4. Shows JSON update reminder with current milestone statuses

### `scripts/finalize_sprint.sh <sprint_id> [version]`
Finalize a completed sprint by moving design docs and updating status.

## Execution Flow

### Phase 0: Session Resumption (for continuing sprints)

**If this is NOT the first session for this sprint:**

```bash
scripts/session_start.sh <sprint-id>
```

This prints "Here's where we left off" summary. **Then skip to Phase 2** to continue with the next milestone.

### Phase 1: Initialize Sprint (first session only)

1. **Validate Sprint JSON** - Run `validate_sprint_json.sh <sprint-id>` **REQUIRED FIRST**
2. **Read Sprint Plan** - Parse markdown + load JSON progress file
3. **Validate Prerequisites** - Run `validate_prerequisites.sh` (tests, linting, git status)
4. **Create Todo List** - Use TodoWrite to track all milestones
5. **Initial Status Update** - Mark sprint as "In Progress"

### Phase 2: Choose Execution Mode

After Phase 1 initialization, choose between sequential or parallel execution based on milestone dependencies.

### Phase 2A: Sequential Execution (default)

**For each milestone:**

1. **Pre-Implementation** - Mark milestone as `in_progress` in TodoWrite
2. **Implement** - Write code
3. **Write Tests** - TDD recommended for complex logic, comprehensive coverage required
4. **Verify Quality** - Run `milestone_checkpoint.sh <milestone-name>` (tests + lint must pass)
5. **Update Documentation**:
   - Changelog (what, LOC, key decisions)
   - Sprint plan markdown (mark milestone as done)
6. **Update Sprint JSON** - CRITICAL - The checkpoint script reminds you!
   - Update `passes: true/false`
   - Set `completed: "<ISO timestamp>"`
   - Add `notes: "<summary of what was done>"`
7. **Pause for Breath** - Show progress, ask user if ready to continue

After all milestones complete, proceed to **Phase 4: Finalize Sprint**.

### Phase 2B: Parallel Milestone Execution

**Use this mode when independent milestones can be developed concurrently using Task sub-agents.**

#### Step 1: Dependency Analysis

Read the sprint plan and build a dependency graph from the milestones. Group milestones into parallelizable waves.

#### Step 2: Spawn Task Sub-Agents Per Milestone

For each parallelizable wave, spawn one Task sub-agent per milestone in a single message. Each sub-agent:
- Works on its own branch (`sprint/<milestone-slug>`)
- Writes failing tests FIRST
- Implements until tests pass
- Commits with milestone reference

#### Step 3: Collect Sub-Agent Results

Parse `MILESTONE_REPORT` blocks from each sub-agent. Handle failures before proceeding.

#### Step 4: Repeat for Each Wave

Execute waves sequentially (Wave 1 -> integrate -> Wave 2 -> integrate -> ...).

### Phase 3: Integration Agent

After parallel milestones complete, merge all milestone branches and verify the combined result.

### Phase 4: Finalize Sprint

1. **Final Testing** - Run `${TEST_CMD}`, `${LINT_CMD}`
2. **Documentation Review** - Verify CHANGELOG, sprint plan complete
3. **Final Commit** - Git commit with sprint summary
4. **Move Design Docs** - Run `finalize_sprint.sh <sprint-id> [version]`
5. **Summary Report** - Compare planned vs actual (LOC, time, velocity)

## Key Features

### Continuous Testing
- Run `${TEST_CMD}` after every file change
- Never proceed if tests fail
- Track test count increase

### Progress Tracking
- TodoWrite shows real-time progress
- Sprint plan updated at each milestone
- CHANGELOG grows incrementally
- JSON file tracks structured state
- Git commits create audit trail

### GitHub Issue Integration

If `github_issues` is set in sprint JSON:
- Milestone checkpoint reminds you to include `Refs #...` in commits
- Finalize script suggests commit message with issue references

**Commit message format:**
```bash
# During development - use "refs" to LINK without closing
git commit -m "Complete M1: Feature description, refs #17"

# Final sprint commit - use "Fixes" to AUTO-CLOSE issues on merge
git commit -m "Finalize sprint M-BUG-FIX

Fixes #17
Fixes #42"
```

### Pause Points
- After each milestone completion
- When tests or linting fail
- When user requests "pause"
- When encountering unexpected issues

### Error Handling
- **If tests fail**: Show output, ask how to fix, don't proceed
- **If linting fails**: Show output, ask how to fix, don't proceed
- **If implementation unclear**: Ask for clarification, don't guess
- **If milestone takes much longer than estimated**: Pause and reassess

## Resources

### Multi-Session State
- **JSON Schema**: [`resources/json_progress_schema.md`](resources/json_progress_schema.md)
- **Milestone Checklist**: [`resources/milestone_checklist.md`](resources/milestone_checklist.md)
- **Developer Tools**: [`resources/developer_tools.md`](resources/developer_tools.md)

## Prerequisites

- Working directory clean (or only sprint-related changes)
- Current branch `dev` or `main` (or specified in sprint plan)
- All existing tests pass
- All existing linting passes
- Sprint plan approved and documented
- JSON progress file created AND POPULATED by sprint-planner (not just template!)
- JSON must pass validation: `scripts/validate_sprint_json.sh <sprint-id>`

## Failure Recovery

### If Tests Fail During Sprint
1. Show test failure output
2. Ask user: "Tests failing. Options: (a) fix now, (b) revert change, (c) pause sprint"
3. Don't proceed until tests pass

### If Velocity Much Lower Than Expected
1. Pause and reassess after 2-3 milestones
2. Calculate actual velocity
3. Propose: (a) continue as-is, (b) reduce scope, (c) extend timeline
4. Update sprint plan with revised estimates

### If Sub-Agent Fails (Parallel Mode)
1. Parse the MILESTONE_REPORT from the failed sub-agent
2. Show failure notes and any test output to the user
3. Options: (a) retry, (b) fix manually, (c) skip
4. Do NOT merge a failed milestone's branch

## Notes

- This skill is long-running - expect it to take hours or days
- Pause points are built in - you're not locked into finishing
- Sprint plan is the source of truth - but reality may require adjustments
- Git commits create a reversible audit trail
- Test-driven development is non-negotiable - tests must pass
- Multi-session continuity - Sprint can span multiple sessions
- Parallel execution - Independent milestones run as concurrent Task sub-agents
