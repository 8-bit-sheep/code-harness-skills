# Issue Closure Guide

How to properly close GitHub issues when making a release.

## Overview

When releasing a new version, issues should be closed with informative comments that include:
1. **Release version and URL** - Link to the GitHub release
2. **Relevant fix reference** - Which feature/fix in the CHANGELOG addresses the issue
3. **Commit hash** (optional) - The specific commit that fixed the issue

## Closing Comment Format

```markdown
Fixed in [vX.X.X](https://github.com/OWNER/REPO/releases/tag/vX.X.X) - Brief description of the fix.

[Optional: More detail about what was fixed]

Commit: [`abc1234`](https://github.com/OWNER/REPO/commit/abc1234567890)
```

## Common Patterns

### Bug Fixes
```markdown
Fixed in [vX.X.X](https://github.com/OWNER/REPO/releases/tag/vX.X.X) - [Describe what was wrong] now [describe correct behavior].
```

### New Features
```markdown
Added in [vX.X.X](https://github.com/OWNER/REPO/releases/tag/vX.X.X) - New `functionName` for [purpose].
```

### With Design Doc
```markdown
Fixed in [vX.X.X](https://github.com/OWNER/REPO/releases/tag/vX.X.X) - Description.

See: [Design Doc](https://github.com/OWNER/REPO/blob/main/design_docs/implemented/vX_X_X/feature.md)
```

## Auto-Close via Commits

Include issue references in commit messages:

```bash
git commit -m "Fix type assertion issue

Fixes #40, Fixes #41"
```

GitHub automatically closes issues when commits with "Fixes #X" are merged to the default branch.

## Tips

1. **Batch similar issues** - Close duplicates with the same comment
2. **Link related issues** - Mention "See also #X"
3. **Be specific** - Generic "fixed" comments don't help users
4. **Include usage** - For new features, show how to use them
5. **Reference design docs** - If there's a design doc, link to it
