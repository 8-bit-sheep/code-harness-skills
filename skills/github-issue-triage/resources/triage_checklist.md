# GitHub Issue Triage Checklist

Use this checklist for periodic issue triage sessions.

## Pre-Triage Setup

- [ ] Check GitHub authentication: `gh auth status`
- [ ] Switch to correct account if needed: `gh auth switch --user <user>`
- [ ] Update local repo: `git pull`

## Generate Triage Report

```bash
scripts/triage_report.sh
```

## Process Closable Issues

- [ ] Review list of closable issues
- [ ] Verify each is truly implemented (check CHANGELOG, design docs)
- [ ] Preview close actions: `scripts/find_closable.sh --dry-run`
- [ ] Close issues: `scripts/find_closable.sh --close`

## Process Orphaned Issues

For each orphaned issue:

- [ ] **Priority check**: Is this critical, important, or nice-to-have?
- [ ] **Feasibility check**: Can we implement this? Resources available?
- [ ] **Scope check**: Does this fit the project's direction?

**Actions:**
- High priority -> Create design doc
- Medium priority -> Add to backlog, label appropriately
- Low priority/out of scope -> Close with explanation

## Process Stale Issues

For each stale issue (no activity 30+ days):

- [ ] Check if still relevant
- [ ] Add comment requesting update
- [ ] Set reminder to close in 14 days if no response

## Handle Bug Reports

For each bug:
- [ ] Reproducible? Ask for steps if not clear
- [ ] Severity? Label: `critical`, `major`, `minor`
- [ ] Workaround available? Document in comments
- [ ] Create design doc if fix is non-trivial

## Handle Feature Requests

For each feature request:
- [ ] Aligns with project goals?
- [ ] Clear use case provided?
- [ ] Duplicates existing issue?
- [ ] Label appropriately

## Update Labels

Standard labels:

| Label | Purpose |
|-------|---------|
| `bug` | Something broken |
| `enhancement` | New feature |
| `documentation` | Docs improvement |
| `good first issue` | Easy to fix |
| `help wanted` | Need community help |
| `wontfix` | Out of scope |
| `duplicate` | Already reported |
| `question` | Needs clarification |
| `in-progress` | Being worked on |

## Post-Triage Summary

- [ ] Note any blocked issues and why
- [ ] Schedule next triage (recommended: weekly)
