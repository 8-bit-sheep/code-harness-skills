# Sprint Progress JSON Schema

This document defines the JSON format for sprint progress tracking, following the [Anthropic long-running agent patterns](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).

## Purpose

The JSON progress file enables **multi-session continuity** by:
- Providing structured, machine-readable progress state
- Following the "constrained modification" pattern (only `passes` field changes)
- Enabling session resumption across multiple sessions
- Supporting velocity tracking and estimation accuracy

## File Location

Sprint progress files are stored in `${SPRINT_STATE_DIR:-.sprint-state}/`:

```
${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json
```

## Schema Definition

### Root Object

```json
{
  "sprint_id": "string",
  "created": "ISO 8601 timestamp",
  "estimated_duration_days": "number",
  "correlation_id": "string",
  "design_doc": "string (path)",
  "markdown_plan": "string (path)",
  "features": [...],
  "velocity": {...},
  "last_session": "ISO 8601 timestamp",
  "last_checkpoint": "string | null",
  "status": "not_started | in_progress | paused | completed"
}
```

### Features Array

Each feature in the sprint:

```json
{
  "id": "string",
  "description": "string",
  "estimated_loc": "number",
  "actual_loc": "number | null",
  "dependencies": ["string"],
  "acceptance_criteria": ["string"],
  "passes": null | true | false,
  "started": "ISO 8601 timestamp | null",
  "completed": "ISO 8601 timestamp | null",
  "notes": "string | null"
}
```

**CRITICAL: Constrained Modification Pattern**

According to the Anthropic article, only the `passes` field should be modified during execution:
- Allowed: Change `passes` from `null` to `true` or `false`
- Allowed: Update `actual_loc`, `completed`, `notes` (progress tracking)
- Forbidden: Change `description`, `acceptance_criteria` (prevents accidental requirement changes)
- Forbidden: Remove features from array (prevents losing work)
- Forbidden: Add new features mid-sprint (add to backlog instead)

### Velocity Object

```json
{
  "target_loc_per_day": "number",
  "actual_loc_per_day": "number",
  "estimated_total_loc": "number",
  "actual_total_loc": "number",
  "estimated_days": "number",
  "actual_days": "number | null"
}
```

## Why JSON Instead of Markdown?

From the Anthropic article:

> **Using structured JSON prevents accidental modifications better than markdown.**

**Benefits:**
1. **Machine-readable**: Easy to parse and validate
2. **Constrained updates**: Clear which fields can/can't change
3. **Atomic updates**: jq can update specific fields safely
4. **Validation**: Can validate schema before/after updates
5. **History tracking**: Git shows exactly what changed

## Validation

### Required Fields

- `sprint_id` - Must be unique
- `created` - ISO 8601 timestamp
- `features[]` - Must have at least one feature
- `features[].id` - Must be unique within sprint
- `features[].passes` - Must be null, true, or false
- `velocity` - All fields must be present
- `status` - Must be valid enum value

### Validation Script

```bash
# Validate JSON structure
jq -e . ${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json >/dev/null

# Check required fields
jq -e '.sprint_id, .created, .features, .velocity, .status' \
  ${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json >/dev/null

# Check passes field only has valid values
jq -e '[.features[].passes] | all(. == null or . == true or . == false)' \
  ${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json
```
