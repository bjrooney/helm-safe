# Branch Protection Setup Guide

This guide walks through setting up branch protection rules for the helm-safe repository to ensure all changes go through pull requests and require approval.

## 🔒 Branch Protection Goals

1. **Require Pull Requests**: No direct pushes to `main` branch
2. **Require Reviews**: All PRs must be approved by repository owner
3. **Status Checks**: Ensure CI/CD passes before merging
4. **Dismiss Stale Reviews**: Re-review required if code changes after approval
5. **Admin Enforcement**: Apply rules to administrators too

## 📋 Setup Instructions

### Step 1: Navigate to Repository Settings

1. Go to: https://github.com/bjrooney/helm-safe
2. Click **Settings** tab (top right of repository page)
3. Click **Branches** in the left sidebar

### Step 2: Add Branch Protection Rule

1. Click **Add rule** button
2. Configure the following settings:

#### Branch Name Pattern
```
main
```

#### Protection Settings (Check these boxes):

- [x] **Require a pull request before merging**
  - [x] **Require approvals** (set to: 1)
  - [x] **Dismiss stale pull request approvals when new commits are pushed**
  - [x] **Require review from code owners** (if you create a CODEOWNERS file)
  - [x] **Restrict pushes that create files that have a path length longer than this limit** (optional)

- [x] **Require status checks to pass before merging**
  - [x] **Require branches to be up to date before merging**
  - Add status checks: `build` (from your GitHub Actions workflow)

- [x] **Require conversation resolution before merging**

- [x] **Require signed commits** (recommended for security)

- [x] **Require linear history** (optional, keeps git history clean)

- [x] **Include administrators** (applies rules to you too - recommended)

- [x] **Restrict pushes** (optional, only allow specific people/teams to push)

- [x] **Allow force pushes** (unchecked - prevents force pushes)

- [x] **Allow deletions** (unchecked - prevents branch deletion)

### Step 3: Create CODEOWNERS File (Optional but Recommended)

Create a file that automatically requests your review:

```bash
# Create CODEOWNERS file
cat > .github/CODEOWNERS << 'EOF'
# Global code owners
* @bjrooney

# Specific file types that need extra attention
*.go @bjrooney
*.yaml @bjrooney
*.yml @bjrooney
Dockerfile* @bjrooney
*.sh @bjrooney

# Critical files
/.github/ @bjrooney
/scripts/ @bjrooney
/pkg/ @bjrooney
plugin.yaml @bjrooney
EOF
```

## 🔄 Workflow After Setup

### For You (Repository Owner)

1. **Create Feature Branch**: `git checkout -b feature/my-feature`
2. **Make Changes**: Develop your feature
3. **Push Branch**: `git push origin feature/my-feature`
4. **Create PR**: Through GitHub UI or CLI
5. **Wait for CI**: Ensure all checks pass
6. **Review & Approve**: Review your own PR (or have someone else review)
7. **Merge**: Click merge button

### For Contributors

1. **Fork Repository** (if external contributor)
2. **Create Feature Branch**: `git checkout -b feature/contributor-feature`
3. **Make Changes**: Develop feature
4. **Push to Fork**: `git push origin feature/contributor-feature`
5. **Create PR**: From fork to main repository
6. **Wait for Review**: You'll review and approve
7. **Address Feedback**: Make any requested changes
8. **Merge**: You merge after approval

## 🚨 Emergency Procedures

### Hotfix Process
If you need to make urgent changes:

1. Create hotfix branch: `git checkout -b hotfix/critical-fix`
2. Make minimal necessary changes
3. Create PR with "HOTFIX:" prefix in title
4. Fast-track review (you can approve immediately)
5. Merge and deploy

### Temporary Rule Bypass
If you absolutely must bypass (not recommended):

1. Go to Settings > Branches
2. Temporarily disable protection rules
3. Make direct push
4. **Immediately re-enable protection rules**
5. Document the emergency action

## 📊 Monitoring & Maintenance

### Regular Reviews
- Weekly: Check for stale branches and clean up
- Monthly: Review protection rule effectiveness
- Quarterly: Audit who has admin access

### Branch Cleanup
```bash
# List merged branches
git branch --merged main

# Delete merged branches (be careful!)
git branch --merged main | grep -v main | xargs git branch -d

# Clean up remote tracking branches
git remote prune origin
```

## 🔧 Advanced Configurations

### Status Check Requirements
Add these status checks as they become available:
- `build` (from GitHub Actions)
- `test` (if you add test workflows)
- `security-scan` (if you add security scanning)
- `docs-build` (if you add documentation builds)

### Auto-merge Settings
For trusted automated PRs (like Dependabot):
- Enable auto-merge for dependency updates
- Require all status checks to pass
- Still require your approval for major version updates

## 📚 References

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [GitHub Flow Guide](https://guides.github.com/introduction/flow/)

---

**⚠️ Important**: After setting up these rules, you'll need to use pull requests for all changes, including your own commits. This is a good practice that ensures code review and CI/CD validation for all changes.