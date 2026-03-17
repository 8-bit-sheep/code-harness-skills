# Design Document Structure Guide

Complete reference for design documents.

## Template Breakdown

### Header Section

```markdown
# [Feature Name]

**Status**: Planned | Implemented
**Target**: v1.2.0
**Priority**: P0 (High) | P1 (Medium) | P2 (Low)
**Estimated**: 3 days
**Dependencies**: None | Feature X, Feature Y
```

### Problem Statement

Describe current pain points with metrics. Quantify impact.

**Good example:**
```markdown
Adding a new module currently takes **7.5 hours** due to:
- Scattered registration across 4 files (2+ hours debugging)
- Verbose configuration (1+ hour trial-and-error)
- Poor error messages (1+ hour debugging)
```

### Goals

Define measurable success criteria. Use before/after comparisons.

### Solution Design

Break into phases with clear deliverables and time estimates.

### Files to Modify/Create

List all files with estimated LOC changes.

### Examples

Show concrete before/after code or workflows.

### Success Criteria

Checkboxes for acceptance tests. Always include "All tests passing" and "Documentation updated."

### Testing Strategy

Break into unit/integration/manual testing.

### Non-Goals

Set boundaries. List what you're NOT doing and why.

### Timeline

Week-by-week breakdown. 2x your initial estimates.

### Risks & Mitigations

List 3-5 main risks with impact ratings and mitigation plans.

### References

Link to related design docs, issues, prior art.

## Implementation Report (for Implemented docs)

Add when moving to `implemented/`:

```markdown
## Implementation Report

**Completed**: [Date]
**Version**: [Version number]

### What Was Built
[Summary vs plan, deviations, what worked well]

### Code Locations
[New files with LOC, modified files with +/- LOC]

### Test Coverage
[Unit/integration test counts, coverage %, test file locations]

### Metrics
[Before/after comparison table]

### Known Limitations
[Edge cases, performance limits, deferred work]
```

## Common Mistakes to Avoid

1. **Vague Problem Statements** - Use metrics, not feelings
2. **Unmeasurable Goals** - "Make things better" vs "Reduce X from 7.5h to 2.5h"
3. **Missing Implementation Details** - "Build everything" vs phased plan with tasks
4. **No Examples** - Show concrete before/after
5. **Unrealistic Estimates** - "Should be quick" vs "3 days (6h impl + 4h test + 2h docs + buffer)"
6. **Missing Success Criteria** - "When it works" vs checkboxes with acceptance tests

## Checklist

**Before creating:**
- [ ] Feature is well-understood
- [ ] Priority and version target are known
- [ ] Similar features reviewed for patterns
- [ ] Dependencies identified

**When creating:**
- [ ] Run `create_planned_doc.sh`
- [ ] Fill in all header metadata
- [ ] Write specific problem statement with metrics
- [ ] Define measurable success criteria
- [ ] Break implementation into phases
- [ ] Include concrete before/after examples
- [ ] Estimate realistically (2x initial guess)
- [ ] List files to create/modify
- [ ] Add testing strategy
- [ ] Define non-goals

**After creating:**
- [ ] Review for clarity and completeness
- [ ] Get feedback if major feature
- [ ] Commit to git

**When moving to implemented:**
- [ ] Run `move_to_implemented.sh`
- [ ] Add implementation report
- [ ] Include actual metrics
- [ ] List known limitations
- [ ] Update CHANGELOG
