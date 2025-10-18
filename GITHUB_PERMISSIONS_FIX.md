# Fixing GitHub Actions Release Permissions

## Problem
GitHub Actions is failing to create releases with a 403 error because the default `GITHUB_TOKEN` doesn't have sufficient permissions.

## Solution Options

### Option A: Update Repository Settings (Recommended)

1. **Go to Repository Settings**:
   - Visit: https://github.com/bjrooney/helm-safe/settings/actions

2. **Update Workflow Permissions**:
   - Go to "Actions" → "General" 
   - Scroll down to "Workflow permissions"
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
   - Click "Save"

### Option B: Update the Workflow File

Add explicit permissions to `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write
  packages: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    # ... rest of the workflow
```

### Option C: Create Personal Access Token

1. **Create PAT**:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Create a new token with `repo` scope

2. **Add to Repository Secrets**:
   - Go to repository Settings → Secrets and variables → Actions
   - Add new secret named `RELEASE_TOKEN`
   - Use this token in the workflow instead of `GITHUB_TOKEN`

## Quick Fix for Current Release

Since we have v0.1.1 tagged and the build succeeded, you can:

1. **Go to**: https://github.com/bjrooney/helm-safe/actions
2. **Find the v0.1.1 workflow run**
3. **Download the artifacts** (if available)
4. **Manually create release**: https://github.com/bjrooney/helm-safe/releases/new
   - Tag: v0.1.1
   - Upload the downloaded binaries

## Testing the Fix

After implementing Option A or B:
1. Create a new test tag: `git tag v0.1.2 && git push origin v0.1.2`
2. Check if the release is created automatically