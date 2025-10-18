#!/bin/bash

# Simple GitHub CLI script to set up basic branch protection for helm-safe repository
# This version excludes status checks to avoid issues with non-existent CI checks

set -e

REPO="bjrooney/helm-safe"
BRANCH="main"

echo "🔒 Setting up basic branch protection for $REPO:$BRANCH"

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

# Create basic branch protection rule (without status checks)
echo "🛡️  Creating basic branch protection rule..."

# Create the JSON payload for branch protection
cat > /tmp/branch_protection_basic.json << 'EOF'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

gh api repos/$REPO/branches/$BRANCH/protection \
  --method PUT \
  --input /tmp/branch_protection_basic.json

if [ $? -eq 0 ]; then
    echo "✅ Basic branch protection rule created successfully!"
    
    # Clean up temporary file
    rm -f /tmp/branch_protection_basic.json
    
    echo ""
    echo "🔧 Configuration applied:"
    echo "  ✓ Require pull request reviews (1 approval required)"
    echo "  ✓ Dismiss stale reviews when new commits are pushed"
    echo "  ✓ Require review from code owners (CODEOWNERS file)"
    echo "  ✓ Include administrators (applies to you too)"
    echo "  ✓ Restrict force pushes"
    echo "  ✓ Restrict branch deletion"
    echo ""
    echo "⚠️  Status checks NOT enabled yet (to avoid errors with non-existent CI)"
    echo ""
    echo "🔄 To add status checks later:"
    echo "  1. Push a commit to trigger GitHub Actions workflow"
    echo "  2. Go to GitHub repo settings > Branches"
    echo "  3. Edit the protection rule"
    echo "  4. Enable 'Require status checks to pass before merging'"
    echo "  5. Select 'build' from the list of available checks"
    echo ""
    echo "🎯 Next steps:"
    echo "  1. All future changes must go through pull requests"
    echo "  2. Each PR requires your approval before merging"
    echo "  3. Once CI runs, you can add status check requirements"
    echo ""
    echo "📚 See BRANCH_PROTECTION_SETUP.md for detailed workflow instructions"
else
    echo "❌ Failed to create branch protection rule"
    
    # Clean up temporary file
    rm -f /tmp/branch_protection_basic.json
    
    echo "   You may need to set this up manually through the GitHub web interface"
    echo "   See BRANCH_PROTECTION_SETUP.md for step-by-step instructions"
    echo ""
    echo "💡 Common issues:"
    echo "   - Repository may not exist or you may not have admin access"
    echo "   - Make sure you're authenticated: gh auth login"
    echo "   - Try the manual setup through GitHub web interface instead"
    exit 1
fi