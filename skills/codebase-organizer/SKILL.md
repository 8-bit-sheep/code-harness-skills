---
name: Codebase Organizer
description: Monitor and refactor large files into smaller, AI-friendly modules. Use when user asks to check file sizes, split large files, or organize the codebase. Ensures tests pass before and after refactoring.
---

# Codebase Organizer

Maintain optimal file sizes for AI-assisted development by splitting large files into focused modules.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SOURCE_DIR` | `.` | Root source directory to scan |
| `FILE_EXT` | `*` | File extension filter (e.g., `*.go`, `*.ts`, `*.py`) |
| `MAX_LINES` | `800` | Maximum lines before file must be split |
| `TEST_CMD` | `make test` | Command to run tests |
| `LINT_CMD` | `make lint` | Command to run linter |

## Quick Start

```bash
# Find large files in your project
find ${SOURCE_DIR:-.} -name "${FILE_EXT:-*}" -exec wc -l {} \; | awk '$1 > 500 {print}' | sort -rn
```

## When to Use This Skill

Invoke when user says:
- "Check file sizes" / "report file sizes"
- "Split this file" / "refactor large file"
- "Organize the codebase"
- "Make files AI-friendly"

## File Size Targets

| Size | Status | Action |
|------|--------|--------|
| 200-500 lines | Sweet spot | None needed |
| 500-800 lines | Acceptable | Consider splitting |
| >800 lines | **CRITICAL** | Must split |

## Workflow

### Step 1: Status Check

```bash
# Find all large files
find ${SOURCE_DIR:-.} -name "${FILE_EXT:-*}" -type f -exec wc -l {} \; | awk '$1 > 500 {print}' | sort -rn
```

**Output format:**
```
CRITICAL (>800 lines):
  src/parser/parser.ts: 2518 lines

WARNING (500-800 lines):
  src/eval/evaluator.py: 765 lines
```

### Step 2: Plan the Split

Before ANY refactoring:

1. **Run baseline tests**: `${TEST_CMD}`
2. **Identify natural boundaries**:
   - Different responsibilities or concerns
   - Public API vs internal helpers
   - Different data types or domains
   - Logical groupings of related functions

3. **Plan file names** (match to primary functions):
   - `expressions.ts` → expression handling
   - `statements.ts` → statement handling
   - `helpers.ts` → utility functions

4. **Check for circular dependency risks**

### Step 3: Execute Split

```bash
# 1. Create new files with clear names
# 2. Move related functions together (maintain cohesion)
# 3. Update imports in all affected files
# 4. Keep main types/structs in the primary file
```

**Keep together:**
- Tightly coupled functions
- Helper functions used by one main function
- Functions that share complex state

### Step 4: Validate

```bash
# MUST run after every split
${TEST_CMD}     # All tests must pass
${LINT_CMD}     # No linting errors
```

**If tests fail:**
1. DO NOT COMMIT
2. Analyze failure (missing import? broken reference?)
3. Fix issue
4. Re-run tests
5. Only commit when tests pass

### Step 5: Document & Commit

Commit with descriptive message:
```bash
git add src/path/*.ext
git commit -m "Split path/file.ext into N files (AI-friendly)

- primary.ext: Main types (200 lines)
- expressions.ext: Expression handling (450 lines)
..."
```

## Error Handling

### Circular Dependency

If split creates circular dependency:

1. **Identify cycle**: File A imports B, File B imports A
2. **Solutions**:
   - Extract shared code to new file (e.g., `types.ext`)
   - Use interfaces to break dependency
   - Restructure to have one-way dependency
   - Merge files if truly inseparable (<800 lines combined)

### Test Failures

Common issues after split:
- Missing import in new file
- Function moved but still referenced in old location
- Test file not updated to match new structure

## Success Metrics

After refactoring:
- 0 files over 800 lines
- <5 files between 500-800 lines
- Average file size: 300-400 lines
- 100% test pass rate maintained

## Important Reminders

- **ALWAYS run tests before and after refactoring**
- **NEVER commit if tests fail**
- **One refactoring at a time** (easier to debug)
- **Show plan before executing** (get user approval)
- **Keep related functions together** (maintain cohesion)
