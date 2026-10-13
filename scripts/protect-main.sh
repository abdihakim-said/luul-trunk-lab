#!/usr/bin/env bash
# Protect the trunk (main) branch using the GitHub CLI.
# Usage: ./scripts/protect-main.sh <owner>/<repo>
set -euo pipefail
REPO="${1:?usage: $0 owner/repo}"

gh api -X PUT "repos/$REPO/branches/main/protection" \
  -H "Accept: application/vnd.github+json" \
  --input - >/dev/null <<JSON
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Lint & unit tests", "Docker build & smoke test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
echo "main is protected on $REPO"
echo "(Required approvals: 0 for a single-maintainer repo. Raise to 1-2 for a team.)"
