# Milestone Execution Checklist

## Pre-Implementation
- [ ] Mark milestone as `in_progress` in TodoWrite
- [ ] Review milestone goals and acceptance criteria
- [ ] Identify files to create/modify
- [ ] Verify estimated LOC matches plan

## Implementation
- [ ] Write implementation code
- [ ] Follow design patterns from sprint plan
- [ ] Add inline comments for complex logic
- [ ] Keep functions small and focused (<50 lines)

## Testing
- [ ] Create/update test files
- [ ] Comprehensive coverage (all acceptance criteria)
- [ ] Include edge cases and error conditions
- [ ] Test both success and failure paths
- [ ] Use realistic-complexity inputs (not just toy examples)

## Quality Verification
- [ ] Run tests: `${TEST_CMD}` - MUST PASS
- [ ] Run linting: `${LINT_CMD}` - MUST PASS
- [ ] Check formatting: `${FMT_CMD}` if available
- [ ] If any fail, fix immediately before proceeding

## Documentation
- [ ] Update CHANGELOG with milestone completion:
  - What was implemented
  - LOC counts (implementation + tests)
  - Key design decisions
  - Files modified/created
- [ ] Update sprint plan with completion status

## Sprint JSON Update (CRITICAL)
- [ ] Update `${SPRINT_STATE_DIR:-.sprint-state}/sprint_<id>.json`:
  - Set `passes: true` (or `false` if failing)
  - Set `completed: "<ISO timestamp>"`
  - Add `notes: "<what was done>"`
- [ ] If sprint is fully complete, change `status: "completed"`

## Pause for Breath
- [ ] Show summary of what was completed
- [ ] Show current sprint progress (X of Y milestones done)
- [ ] Show velocity (LOC/day vs planned)
- [ ] Ask user: "Ready to continue to next milestone?"
- [ ] If user says "pause" or "stop", save state and exit gracefully

## Commit (After Quality Checks Pass)
- [ ] Stage files: `git add <files>`
- [ ] Commit with descriptive message
- [ ] Include milestone name and key changes
- [ ] Push if appropriate

## Milestone Complete
- [ ] Mark milestone as `completed` in TodoWrite
- [ ] Move to next milestone or finalize sprint
