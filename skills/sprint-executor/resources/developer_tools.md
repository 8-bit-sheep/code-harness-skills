# Developer Tools Quick Reference

**For sprint-executor skill** - Load this when you need to know which tools are available for specific development tasks.

## Core Development Tools

### Building & Testing

```bash
# Build
${BUILD_CMD:-make build}

# Test
${TEST_CMD:-make test}

# Lint
${LINT_CMD:-make lint}

# Format
${FMT_CMD:-make fmt}
```

### Common Workflows

#### During Sprint Execution

```bash
# After each code change
${BUILD_CMD:-make build}
${TEST_CMD:-make test}
${LINT_CMD:-make lint}

# At milestone checkpoints
scripts/milestone_checkpoint.sh "Milestone name"

# Before committing
${TEST_CMD:-make test}
${LINT_CMD:-make lint}
```

## Tool Discovery Cheat Sheet

| I need to... | Tool |
|--------------|------|
| Build | `${BUILD_CMD}` |
| Run all tests | `${TEST_CMD}` |
| Format code | `${FMT_CMD}` |
| Lint code | `${LINT_CMD}` |

## Emergency Recovery

### Tests Failing During Sprint

```bash
# 1. Show test output
${TEST_CMD:-make test}

# 2. Options:
# (a) Fix now - implement fix
# (b) Revert change - git restore <file>
# (c) Pause sprint - commit WIP, resume later
```

### Linting Failing During Sprint

```bash
# 1. Try auto-fix
${FMT_CMD:-make fmt}

# 2. If still failing, show output
${LINT_CMD:-make lint}

# 3. Fix manually or ask for guidance
```
