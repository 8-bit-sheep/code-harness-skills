---
name: GitHub Issue Triage
description: Monitor and triage GitHub issues against design docs and implementation status. Use when user asks to "check issues", "triage issues", "sync issues", "what issues are open", or wants to ensure issues are up-to-date with development progress.
---

# GitHub Issue Triage

**Monitor open GitHub issues, match them to design docs, identify closable issues, and keep the issue tracker synchronized with actual development progress.**

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `GITHUB_REPO` | _(from git remote)_ | GitHub repository (owner/repo) |
| `DESIGN_DOCS_DIR` | `design_docs` | Root directory for design documents |
| `CHANGELOG_PATH` | `CHANGELOG.md` | Path to changelog file |
| `GITHUB_EXPECTED_USER` | _(none)_ | Expected GitHub CLI user (for auth verification) |
| `STALE_DAYS` | `30` | Days of inactivity before an issue is considered stale |

## Quick Start

```bash
# Full triage report
scripts/triage_report.sh

# Just list open issues with labels and age
scripts/list_open_issues.sh

# Find issues that have been implemented
scripts/find_closable.sh

# Match issues to planned design docs
scripts/match_design_docs.sh --planned
```

## When to Use This Skill

Invoke this skill when:
- User asks "what issues are open?", "check our issues", "triage issues"
- Starting a new development cycle and need to understand backlog
- After completing a release to identify closable issues
- Periodic housekeeping to keep issue tracker clean
- User wants to understand which issues are covered by design docs

## Available Scripts

### `scripts/check_auth.sh`
Verify GitHub CLI authentication matches expected user.

**What it checks:**
1. `gh` CLI is installed
2. User is authenticated to github.com
3. Active account matches `GITHUB_EXPECTED_USER` if set

### `scripts/list_open_issues.sh [--json] [--labels LABELS]`
List all open GitHub issues with details.

**Output includes:**
- Issue number and title
- Labels
- Age (days since creation)
- Last updated date
- Assignee (if any)

### `scripts/match_design_docs.sh [--planned] [--implemented] [--all]`
Match open issues to design documents.

**Matching strategy:**
1. Exact issue number references (`#123` in design doc)
2. Title keyword matching (significant words from issue title)
3. Bug ID matching (`M-BUG-XXX` patterns)

### `scripts/find_closable.sh [--close] [--dry-run]`
Find issues that have been implemented and can be closed.

**What it checks:**
1. Issue referenced in `${DESIGN_DOCS_DIR}/implemented/`
2. Issue mentioned in CHANGELOG
3. Issue keywords match implemented features

### `scripts/triage_report.sh [--output FILE]`
Generate a complete triage report combining all analysis.

**Report includes:**
1. **Summary**: Total open, covered, closable, orphaned
2. **Closable Issues**: Ready to close (implemented)
3. **Covered Issues**: Have design docs (in progress)
4. **Orphaned Issues**: No design doc coverage (need attention)
5. **Stale Issues**: No activity in 30+ days
6. **Recommendations**: Suggested actions

## Triage Workflow

### 1. Check Authentication

```bash
scripts/check_auth.sh
```

### 2. Generate Triage Report

```bash
scripts/triage_report.sh
```

### 3. Handle Closable Issues

```bash
# Preview what would be closed
scripts/find_closable.sh --dry-run

# Close with proper comments
scripts/find_closable.sh --close
```

### 4. Review Orphaned Issues

For issues without design doc coverage:
1. Assess priority and feasibility
2. Create design doc if work should proceed
3. Close with "won't fix" if out of scope
4. Add to backlog for future versions

### 5. Handle Stale Issues

For issues with no activity in 30+ days:
1. Check if still relevant
2. Add comment requesting update from reporter
3. Close if no response after additional time

## Integration with Other Skills

### With release-manager
```bash
# Before release: find issues to close
scripts/find_closable.sh

# During release: close issues
release-manager/scripts/collect_closable_issues.sh 1.2.0 --close
```

### With design-doc-creator
```bash
# Find uncovered issues, then create design doc
scripts/match_design_docs.sh --planned
# For uncovered issue #42:
# Use design-doc-creator to create a design doc
```

### With sprint-planner
```bash
# Use triage report to inform sprint scope
scripts/triage_report.sh --output /tmp/triage.md
# Include high-priority uncovered issues in sprint
```

## Resources

### Triage Checklist
See [`resources/triage_checklist.md`](resources/triage_checklist.md) for step-by-step checklist.

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Correct user active (`gh auth status`)
- Repository access

## Notes

- All scripts check auth before making changes
- Close operations add proper comments with release/commit references
- Can be adapted for any GitHub repository
