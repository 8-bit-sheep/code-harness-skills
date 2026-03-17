---
name: Release Manager
description: Create new releases with version bumps, changelog updates, git tags, and CI/CD verification. Use when user says "ready to release", "create release", mentions version numbers, or wants to publish a new version.
---

# Release Manager

Create a complete release with version bump, changelog update, git tag, and CI/CD verification.

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `TEST_CMD` | `make test` | Command to run tests |
| `LINT_CMD` | `make lint` | Command to run linting |
| `CHANGELOG_PATH` | `CHANGELOG.md` | Path to changelog file |
| `VERSION_FILE` | `VERSION` | Path to version file |
| `DESIGN_DOCS_DIR` | `design_docs` | Root directory for design documents |
| `GITHUB_REPO` | _(from git remote)_ | GitHub repository (owner/repo) |

## Quick Start

```bash
# User says: "Ready to release v1.2.0"
# This skill will:
# 1. Run pre-release checks (tests, lint)
# 2. Update version in docs
# 3. Create git tag
# 4. Push to trigger CI/CD
# 5. Verify release artifacts
```

## When to Use This Skill

Invoke this skill when:
- User says "ready to release", "create release", "publish release"
- User mentions a specific version number
- User asks about release process or workflow
- After completing a sprint and code is ready to ship

## Available Scripts

### `scripts/pre_release_checks.sh`
Run all pre-release verification checks.

**What it checks:**
1. Test suite passes (`${TEST_CMD}`)
2. Linting passes (`${LINT_CMD}`)

### `scripts/post_release_checks.sh <version>`
Verify release was created successfully on GitHub.

**What it checks:**
1. Git tag exists
2. GitHub release exists
3. Platform binaries present (if applicable)
4. Latest CI run passed

### `scripts/check_implemented_docs.sh <version>`
Verify all implemented design docs are documented in CHANGELOG.

### `scripts/collect_closable_issues.sh <version> [--close] [--json]`
Find GitHub issues that can be closed with this release.

**What it scans:**
1. Commits since last tag for issue references (Fixes #123, Closes #456, etc.)
2. CHANGELOG entry for the version
3. Design docs in `${DESIGN_DOCS_DIR}/implemented/`

### `scripts/close_issues_with_references.sh <version> <issue> [section]`
Close a GitHub issue with proper release references (URLs, commits, design docs).

## Release Workflow

### 1. Pre-Release Verification (CRITICAL)

```bash
scripts/pre_release_checks.sh
```

**If checks fail:**
- Tests failing -> Fix tests first
- Linting failing -> Run `${FMT_CMD:-make fmt}` or fix issues
- **DO NOT proceed until all checks pass**

### 2. Verify Implemented Design Docs

```bash
scripts/check_implemented_docs.sh X.X.X
```

### 3. Update Version in Documentation

Update these files:
- **${CHANGELOG_PATH}**: Change `## [Unreleased]` to `## [vX.X.X] - YYYY-MM-DD`
- **${VERSION_FILE}**: Update to `vX.X.X`
- Any other version-dependent files in your project

### 4. Post-Update Verification

```bash
${TEST_CMD:-make test}
${LINT_CMD:-make lint}
```

### 5. Commit Changes

```bash
git add ${CHANGELOG_PATH} ${VERSION_FILE}
git commit -m "Release vX.X.X"
```

### 6. Create and Push Git Tag

```bash
git tag -a vX.X.X -m "Release vX.X.X"
git push origin $(git branch --show-current)
git push origin vX.X.X
```

### 7. Monitor CI/CD

```bash
gh run list --limit 3
gh run watch
```

### 8. Collect and Close Related Issues

```bash
scripts/collect_closable_issues.sh X.X.X
scripts/collect_closable_issues.sh X.X.X --close
```

### 9. Verify Release

```bash
scripts/post_release_checks.sh X.X.X
```

### 10. Handle CI Failures

If CI fails after push:
```bash
gh run list --limit 3
gh run view <run-id> --log-failed
# Fix issues, commit, push again
```

## Resources

### Release Checklist
See [`resources/release_checklist.md`](resources/release_checklist.md) for complete step-by-step checklist.

### Issue Closure Guide
See [`resources/issue_closure_guide.md`](resources/issue_closure_guide.md) for how to properly close GitHub issues.

## Prerequisites

- Working directory must be clean (no uncommitted changes)
- All tests must pass
- All linting must pass

## Version Format

Semantic versioning: `MAJOR.MINOR.PATCH`
- Examples: `0.0.9`, `0.1.0`, `1.0.0`

## Common Issues

### Tests Fail Before Release
**Solution**: Fix tests first, don't skip this step.

### Linting Fails
**Solution**: Run `${FMT_CMD:-make fmt}` to auto-format, or fix manually.

### CI Fails After Push
**Solution**: Check logs with `gh run view <run-id> --log-failed`, fix, commit, push again.

## Progressive Disclosure

1. **Always loaded**: This SKILL.md file
2. **Execute as needed**: Scripts in `scripts/`
3. **Load on demand**: `resources/release_checklist.md`

## Notes

- Always run pre-release checks BEFORE making changes
- Always run post-update checks AFTER documentation changes
- Scripts handle verification automatically
