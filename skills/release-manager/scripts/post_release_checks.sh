#!/usr/bin/env bash
# Verify release was created successfully
#
# Usage: post_release_checks.sh <version>
#
# Environment variables:
#   GITHUB_REPO - GitHub repository (default: auto-detected from git remote)

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <version>" >&2
    echo "Example: $0 1.2.0" >&2
    exit 1
fi

VERSION="$1"
TAG="v$VERSION"

# Auto-detect repo if not set
if [[ -z "${GITHUB_REPO:-}" ]]; then
    GITHUB_REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' | sed 's|\.git$||' || echo "")
fi

echo "Verifying release $TAG..."
echo

FAILURES=0

# Check git tag exists
echo "1/4 Checking git tag..."
if git tag -l "$TAG" | grep -q "$TAG"; then
    echo "  OK Tag $TAG exists"
else
    echo "  FAIL Tag $TAG not found"
    FAILURES=$((FAILURES + 1))
fi
echo

# Check GitHub release exists
echo "2/4 Checking GitHub release..."
if gh release view "$TAG" > /dev/null 2>&1; then
    echo "  OK GitHub release $TAG exists"
else
    echo "  FAIL GitHub release $TAG not found"
    FAILURES=$((FAILURES + 1))
fi
echo

# Check release assets
echo "3/4 Checking release assets..."
ASSET_COUNT=$(gh release view "$TAG" --json assets --jq ".assets | length" 2>/dev/null || echo "0")
if [[ "$ASSET_COUNT" -gt 0 ]]; then
    echo "  OK $ASSET_COUNT asset(s) found"
    gh release view "$TAG" --json assets --jq ".assets[].name" 2>/dev/null | sed 's/^/    /'
else
    echo "  INFO No assets attached (may still be building)"
fi
echo

# Check CI status
echo "4/4 Checking CI status..."
if gh run list --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null | grep -q "success"; then
    echo "  OK Latest CI run passed"
else
    echo "  WARNING Latest CI run did not pass (may still be running)"
    echo "  Check with: gh run list --limit 3"
fi
echo

# Summary
if [[ $FAILURES -eq 0 ]]; then
    echo "Release $TAG verified successfully!"
    if [[ -n "$GITHUB_REPO" ]]; then
        echo "URL: https://github.com/$GITHUB_REPO/releases/tag/$TAG"
    fi
    exit 0
else
    echo "$FAILURES check(s) failed"
    echo "Release may be incomplete."
    exit 1
fi
