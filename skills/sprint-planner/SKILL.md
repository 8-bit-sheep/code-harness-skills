---
name: Sprint Planner
description: Analyze design docs, calculate velocity from recent work, and create realistic sprint plans with day-by-day breakdowns. Use when user asks to "plan sprint", "create sprint plan", or wants to estimate development timeline.
---

# Sprint Planner

Create comprehensive, data-driven sprint plans by analyzing design documentation, current implementation status, and recent velocity.

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `SPRINT_STATE_DIR` | `.sprint-state` | Directory for sprint JSON progress files |
| `DESIGN_DOCS_DIR` | `design_docs` | Root directory for design documents |
| `CHANGELOG_PATH` | `CHANGELOG.md` | Path to changelog file |
| `BUILD_CMD` | `make build` | Command to build the project |
| `TEST_CMD` | `make test` | Command to run tests |
| `LINT_CMD` | `make lint` | Command to run linting |

## Quick Start

**Most common usage:**
```bash
# User says: "Plan the next sprint based on the v2.0 roadmap"
# This skill will:
# 1. Read design doc (design_docs/planned/v2-roadmap.md)
# 2. Analyze CHANGELOG for recent velocity
# 3. Review current implementation status
# 4. Propose realistic milestones with LOC estimates
# 5. Create day-by-day task breakdown
```

## When to Use This Skill

Invoke this skill when:
- User says "plan sprint", "create sprint plan", "plan next phase"
- User asks to estimate timeline for a feature or design doc
- User wants to know how long implementation will take
- User needs to prioritize work for upcoming development

## Role in Long-Running Agent Pattern

**sprint-planner acts as the "Initializer" agent** in the two-phase pattern from [Anthropic's long-running agent article](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents):

- **Initializer (sprint-planner)**: Creates infrastructure for execution
  - Analyzes design docs and calculates velocity
  - Creates markdown sprint plan (human-readable)
  - Creates JSON progress file (machine-readable)
  - Sets up session resumption infrastructure
  - Sends handoff message to sprint-executor

- **Coding Agent (sprint-executor)**: Works incrementally across sessions
  - Reads JSON progress file on each session start
  - Updates only `passes` field as milestones complete
  - Can pause/resume work across multiple sessions

This separation enables **multi-session continuity** - sprints can span days or weeks with the agent resuming work from where it left off.

## Available Scripts

### `scripts/analyze_velocity.sh [days]`
Analyze recent development velocity from CHANGELOG and git commits.

**Usage:**
```bash
# Analyze last 7 days (default)
scripts/analyze_velocity.sh

# Analyze last 14 days
scripts/analyze_velocity.sh 14
```

### `scripts/create_sprint_json.sh <sprint_id> <sprint_plan_md> [design_doc_md]`
Create structured JSON progress file for multi-session sprint execution.

**Usage:**
```bash
scripts/create_sprint_json.sh \
  "M-S1" \
  "${DESIGN_DOCS_DIR:-design_docs}/planned/v2_0/m-s1-sprint-plan.md" \
  "${DESIGN_DOCS_DIR:-design_docs}/planned/v2_0/m-s1-feature.md"
```

**What it does:**
- Creates `${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json` with feature list
- Implements "constrained modification" pattern (only `passes` field changes)
- Enables session resumption via structured state
- Extracts milestones from sprint plan markdown automatically
- Discovers linked GitHub issues from design doc references

## Sprint Planning Workflow

**CRITICAL: Always end by handing off to sprint-executor after user approval!**

### 1. Read and Analyze Design Document

**Input**: Path to design doc (e.g., `design_docs/planned/v2-roadmap.md`)

**What to extract:**
- Completed milestones (marked with checkmarks)
- Remaining milestones (marked as pending)
- Target metrics (LOC estimates, timeline, acceptance criteria)
- Dependencies between milestones

### 2. Review Current Implementation Status

**Check these sources:**
- `${CHANGELOG_PATH:-CHANGELOG.md}` - Recent features and LOC counts
- `git log --oneline --since="1 week ago"` - Actual commits
- Design doc vs reality - gaps or partial implementations

### 3. Analyze Recent Velocity

**Use the velocity script:**
```bash
scripts/analyze_velocity.sh
```

**Calculate:**
- LOC per day from recent milestones
- Average milestone duration
- Actual completion rate vs estimates

### 4. Identify Remaining Work

**List incomplete milestones with:**
- Dependencies (what blocks what)
- Estimated effort (from design doc)
- Priority (based on dependencies, critical path)
- Current velocity (can we realistically do this?)

### 5. Propose Sprint Plan

**Use the template:**
See [`resources/sprint_plan_template.md`](resources/sprint_plan_template.md)

**Include:**
- **Sprint Summary**: Goal, duration, key deliverables
- **Milestone Breakdown**: For each milestone:
  - Name and description
  - Estimated LOC (implementation + tests)
  - Dependencies
  - Acceptance criteria
  - Risk factors
- **Task List**: Day-by-day breakdown (if < 1 week) or weekly (if longer)
- **Success Metrics**:
  - Test coverage target
  - Docs to update

### 6. Present for Feedback

**Show user:**
- Proposed milestones with estimates
- Assumptions made
- Areas where input is needed
- Realistic timeline based on actual velocity

**Be ready to revise** based on user priorities or constraints.

### 7. Finalize and Document

**Once approved:**
```bash
# Create sprint plan document (markdown - human-readable)
# Naming: M-<type><number>.md (M-P1 for parser, M-T1 for types, etc.)
```

**Create JSON progress file (machine-readable):**
```bash
scripts/create_sprint_json.sh \
  "<sprint-id>" \
  "${DESIGN_DOCS_DIR:-design_docs}/planned/<sprint-id>-plan.md" \
  "${DESIGN_DOCS_DIR:-design_docs}/planned/<feature>-design.md"
```

### 8. MANDATORY: Populate JSON with Real Milestones

**The script creates a TEMPLATE - you MUST populate it with real data!**

**Required edits to `${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json`:**

1. **Replace placeholder features array** with real milestones:
   ```json
   "features": [
     {
       "id": "M1_ACTUAL_NAME",
       "description": "Real description from your sprint plan",
       "estimated_loc": 150,
       "dependencies": [],
       "acceptance_criteria": [
         "Actual criterion from sprint plan",
         "Another real criterion"
       ],
       "passes": null,
       "started": null,
       "completed": null,
       "notes": null
     }
   ]
   ```

2. **Update velocity estimates** to match your sprint plan

**Validation checklist before handoff:**
- [ ] No milestone has `"id": "MILESTONE_ID"` (placeholder)
- [ ] Each milestone has real acceptance criteria (not "Criterion 1")
- [ ] `estimated_total_loc` matches sum of milestone LOC
- [ ] `estimated_days` matches sprint plan duration
- [ ] At least 2 milestones defined

**sprint-executor will REJECT the sprint if placeholders remain!**

### 9. Link GitHub Issues

If your project tracks issues via GitHub, link them to the sprint:

**Important: "refs" vs "Fixes"**
- `refs #17` - Links commit to issue (NO auto-close) - use during development
- `Fixes #17`, `Closes #17`, `Resolves #17` - AUTO-CLOSES issue when merged - use in final commit

**Manual linking:**
```bash
jq '.github_issues = [17, 42]' ${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json > tmp && mv tmp ${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json
```

### 10. ALWAYS Hand Off to sprint-executor

**CRITICAL: After creating an approved sprint plan, ALWAYS hand off to sprint-executor immediately.**

**Optional: Commit before handoff:**
```bash
git add ${DESIGN_DOCS_DIR:-design_docs}/planned/M-<milestone>.md
git add ${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json
git commit -m "Add M-<milestone> sprint plan with JSON progress tracking"
```

## Analysis Framework

### Design Doc Analysis Checklist
- [ ] Current status: What's done vs pending
- [ ] Timeline: Days/weeks remaining, velocity metrics
- [ ] Priority matrix: Critical vs nice-to-have
- [ ] Deferred items: Features pushed to later versions
- [ ] Technical debt: Known issues or limitations

### Implementation Analysis Checklist
- [ ] CHANGELOG: Recent features, LOC counts, test counts
- [ ] Git history: Actual work done (not just documented)
- [ ] Test files: Coverage, test counts, test patterns
- [ ] Code files: Actual implementation, not just stubs
- [ ] TODO/FIXME: Inline comments about future work

### Gap Analysis Checklist
- [ ] Features in design doc but not implemented
- [ ] Features implemented but not in design doc
- [ ] Estimated LOC vs actual LOC (for velocity)
- [ ] Planned vs actual timeline
- [ ] Test coverage gaps
- [ ] Documentation gaps

## Resources

### Sprint Plan Template
See [`resources/sprint_plan_template.md`](resources/sprint_plan_template.md) for complete sprint plan structure.

## Best Practices

### 1. Be Conservative with Estimates
- Use actual velocity from recent work
- Add 20-30% buffer for unknowns
- Don't promise more than recent velocity suggests

### 2. Prioritize Ruthlessly
- Focus on highest-value items first
- Don't try to do everything in one sprint
- Defer nice-to-haves to future sprints

### 3. Make Tasks Concrete
- Bad: "Implement X" is too vague
- Good: "Write parser for X syntax (~100 LOC) + 15 test cases" is concrete
- Each task should be achievable in 1 day or less

### 4. Consider Technical Debt
- Don't just add features, also fix issues
- Balance new work with quality improvements
- Factor in time for bug fixes and refactoring

### 5. Plan for Testing
- Every feature needs tests
- Test LOC is usually 30-50% of implementation LOC
- Include test writing in timeline estimates

### 6. Document Assumptions
- Make implicit assumptions explicit
- Note areas of uncertainty
- Highlight where you need user input

### 7. Verify Design Doc Has Systemic Analysis

**Before planning a sprint for a bug fix, verify the design doc addresses systemic issues.**

**Quick check:** Does the design doc mention:
- [ ] Search for similar code paths performed?
- [ ] Other types/cases checked for same gap?
- [ ] Unified fix covering all cases (not just reported one)?

**If not:** Ask user to revise design doc before planning sprint.

## Output Format

See [`resources/sprint_plan_template.md`](resources/sprint_plan_template.md) for full template.

**Key sections:**
- Summary (goal, duration, risk level)
- Current status analysis (completed, velocity, remaining)
- Proposed milestones (with tasks, criteria, risks)
- Success metrics
- Dependencies and open questions

## Progressive Disclosure

This skill loads information progressively:

1. **Always loaded**: This SKILL.md file (YAML frontmatter + workflow)
2. **Execute as needed**: Scripts in `scripts/` (velocity analysis)
3. **Load on demand**: `resources/sprint_plan_template.md` (template)

Scripts execute without loading into context window, saving tokens.

## Notes

- This skill is interactive - expect back-and-forth with user
- Sprint plans should be realistic, not aspirational
- Use actual data (velocity, LOC counts) over guesses
- Update design docs as reality diverges from plan
- Don't commit plan until approved by user
