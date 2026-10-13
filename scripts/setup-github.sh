#!/usr/bin/env bash
# One-time GitHub setup that a platform engineer does for a trunk-based repo.
# Usage: ./scripts/setup-github.sh <owner>/<repo>
set -euo pipefail
REPO="${1:?usage: $0 owner/repo}"

echo "==> 1. Merge settings: only squash-merge, auto-delete branches after merge"
gh repo edit "$REPO" \
  --enable-squash-merge \
  --enable-merge-commit=false \
  --enable-rebase-merge=false \
  --delete-branch-on-merge

echo "==> 2. Environments: dev, staging, prod (prod needs YOUR approval)"
gh api -X PUT "repos/$REPO/environments/dev" >/dev/null
gh api -X PUT "repos/$REPO/environments/staging" >/dev/null
MY_ID=$(gh api user -q .id)
gh api -X PUT "repos/$REPO/environments/prod" \
  -F "reviewers[][type]=User" -F "reviewers[][id]=$MY_ID" >/dev/null

echo "==> 3. Protect the trunk"
"$(dirname "$0")/protect-main.sh" "$REPO"

echo "Done. Open https://github.com/$REPO/settings to see what changed."
