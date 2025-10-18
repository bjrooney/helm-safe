#!/bin/bash

# GitHub CLI script to set up branch protection for helm-safe repository
# Run this script if you have GitHub CLI installed and authenticated

set -e

REPO="bjrooney/helm-safe"
BRANCH="main"

echo "🔒 Setting up branch protection for $REPO:$BRANCH"

# Check if gh CLI is available
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) not found. Please install it or use the manual setup guide."
    echo "   Install: brew install gh"
    echo "   Or follow: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub CLI. Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is ready"

# Create branch protection rule
echo "🛡️  Creating branch protection rule..."

gh api repos/$REPO/branches/$BRANCH/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["build"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  --field restrictions=null \
  --field allow_force_pushes=false \
  --field allow_deletions=false

if [ $? -eq 0 ]; then
    echo "✅ Branch protection rule created successfully!"
    echo ""
    echo "🔧 Configuration applied:"
    echo "  ✓ Require pull request reviews (1 approval required)"
    echo "  ✓ Dismiss stale reviews when new commits are pushed"
    echo "  ✓ Require review from code owners (CODEOWNERS file)"
    echo "  ✓ Require status checks to pass (build)"
    echo "  ✓ Require branches to be up to date before merging"
    echo "  ✓ Include administrators (applies to you too)"
    echo "  ✓ Restrict force pushes"
    echo "  ✓ Restrict branch deletion"
    echo ""
    echo "🎯 Next steps:"
    echo "  1. All future changes must go through pull requests"
    echo "  2. Each PR requires your approval before merging"
    echo "  3. CI must pass before merging is allowed"
    echo ""
    echo "📚 See BRANCH_PROTECTION_SETUP.md for detailed workflow instructions"
else
    echo "❌ Failed to create branch protection rule"
    echo "   You may need to set this up manually through the GitHub web interface"
    echo "   See BRANCH_PROTECTION_SETUP.md for step-by-step instructions"
    exit 1
fi