---
name: Test Coverage Guardian
description: Analyze test coverage, identify gaps, detect dead code, and improve test quality. Use when user asks to check coverage, review tests, find untested code, or improve test robustness.
---

# Test Coverage Guardian

Analyze and improve test coverage for any codebase.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `COVERAGE_CMD` | `make test-coverage` | Command to generate coverage report |
| `COVERAGE_TARGET` | `80` | Target coverage percentage for core modules |
| `TEST_CMD` | `make test` | Command to run tests |

## Quick Start

**Language-specific coverage commands:**

```bash
# Go
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out

# Python
pytest --cov=src --cov-report=term-missing
coverage run -m pytest && coverage report

# JavaScript/TypeScript
npx jest --coverage
npx vitest --coverage

# Rust
cargo tarpaulin --out Html
```

## When to Use This Skill

Invoke when user says:
- "Check test coverage"
- "What's untested?"
- "Review the test suite"
- "Find dead code"
- "Tests keep breaking" (brittleness analysis)

## Analysis Workflow

### Step 1: Get Current Coverage

Run your project's coverage command and capture the output. Look for overall percentage and per-module/file breakdown.

### Step 2: Identify Gaps

```bash
# Go: Find 0% coverage functions
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out | grep "0.0%"

# Python: Show missing lines
pytest --cov=src --cov-report=term-missing

# JS/TS: Check lcov report
npx jest --coverage --coverageReporters=text
```

### Step 3: Categorize Gaps

| Category | Action |
|----------|--------|
| Core logic uncovered | Write tests (high priority) |
| Error paths uncovered | Add error case tests |
| Dead code (never called) | Consider removal |
| Experimental code | Accept lower coverage |

### Step 4: Report Findings

```markdown
## Coverage Report

### Summary
- Overall: X%
- Core modules: Y%
- Target: ${COVERAGE_TARGET}%+ overall

### Critical Gaps
1. src/types/unifier.ts - type unification (0%)
2. src/eval/effects.py - effect handlers (15%)

### Dead Code Candidates
- src/legacy/old_parser.go (0%, no references)

### Recommendations
1. Add tests for critical gap #1
2. Add integration tests for #2
3. Remove dead code candidates
```

## Coverage Standards

Set targets appropriate to your project:

| Module Type | Recommended Target |
|-------------|-------------------|
| Core logic / business rules | 80%+ |
| API handlers / controllers | 70%+ |
| Utilities / helpers | 70%+ |
| UI components | 60%+ |
| Configuration / setup | 50%+ |

**Critical paths (aim for 100%):**
- Authentication and authorization
- Data validation and sanitization
- Financial calculations
- Security-sensitive code paths

## Test Quality Checklist

### Anti-Brittleness
- [ ] Tests public APIs, not private implementation
- [ ] Uses interface-based testing where appropriate
- [ ] Tests error types, not exact messages
- [ ] Mocks external dependencies at boundaries
- [ ] Tests behavior, not call sequences

### Good Patterns
- [ ] Table-driven tests for comprehensive inputs
- [ ] Property-based tests for invariants
- [ ] Error path testing
- [ ] Integration tests at module boundaries

## CI/CD Monitoring

```bash
# View recent CI runs
gh run list --limit 10

# Check failed run
gh run view <run-id> --log-failed

# Watch run in progress
gh run watch <run-id>
```

## Quality Gates

- No PR should decrease overall coverage
- New features must include tests
- Bug fixes must include regression tests
- Breaking changes require test updates

## Tips

- **Focus on branch coverage**, not just line coverage
- **Test the sad path** - error conditions matter
- **Golden tests** for complex outputs (parser, codegen)
- **Property tests** for mathematical invariants
