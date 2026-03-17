# Release Checklist

## Pre-Release (REQUIRED)

- [ ] All tests pass (`${TEST_CMD}`)
- [ ] All linting passes (`${LINT_CMD}`)
- [ ] Working directory is clean (`git status --short` shows nothing)

## Version Updates

- [ ] CHANGELOG: Change `## [Unreleased]` to `## [vX.X.X] - YYYY-MM-DD`
- [ ] VERSION file: Update to `vX.X.X`
- [ ] Any other version-dependent files

## Post-Update Verification (REQUIRED)

- [ ] Tests still pass after documentation changes
- [ ] Linting still passes after documentation changes

## Git Operations

- [ ] Stage changes: `git add CHANGELOG.md VERSION`
- [ ] Commit: `git commit -m "Release vX.X.X"`
- [ ] Create annotated tag: `git tag -a vX.X.X -m "Release vX.X.X"`
- [ ] Push tag: `git push origin vX.X.X`
- [ ] Push commit: `git push`

## CI/CD Monitoring

- [ ] Check CI status: `gh run list --limit 3`
- [ ] Verify builds pass on all platforms
- [ ] Wait for release workflow to complete

## Release Verification

- [ ] Release created: `gh release view vX.X.X`
- [ ] Platform binaries present (if applicable)
- [ ] Release is published (not draft)
- [ ] Release notes are present

## If CI Fails

- [ ] Check logs: `gh run view <run-id> --log-failed`
- [ ] Fix issues
- [ ] Commit fixes
- [ ] Push again
- [ ] Verify all checks pass

## Version Format

Semantic versioning: `MAJOR.MINOR.PATCH`
