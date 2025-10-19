# Workflow Permissions Fix

Since the OAuth token doesn't have workflow scope, the workflow file needs to be updated manually on GitHub.

## Step-by-Step Instructions

### 1. Go to the workflow file on GitHub
Visit: https://github.com/bjrooney/helm-safe/blob/main/.github/workflows/release.yml

### 2. Click "Edit this file" (pencil icon)

### 3. Add permissions section
After line 6 (after the `tags:` section), add these lines:

```yaml
# Add explicit permissions for release creation
permissions:
  contents: write
  packages: write
```

### 4. The complete file should look like this:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

# Add explicit permissions for release creation
permissions:
  contents: write
  packages: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'
    
    - name: Build for all platforms
      run: make cross-build
    
    - name: Package binaries
      run: |
        mkdir -p dist
        for binary in bin/helm-safe-*; do
          if [[ "$binary" == *".exe" ]]; then
            # Windows binary
            platform=$(basename "$binary" .exe | sed 's/helm-safe-//')
            tar czf "dist/helm-safe-${platform}.tar.gz" -C bin "$(basename "$binary")"
          else
            # Unix binary
            platform=$(basename "$binary" | sed 's/helm-safe-//')
            tar czf "dist/helm-safe-${platform}.tar.gz" -C bin "$(basename "$binary")"
          fi
        done
    
    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: dist/*.tar.gz
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 5. Commit the changes
- Add a commit message: "Add workflow permissions to fix release creation"
- Click "Commit changes"

### 6. Test the fix
After the workflow is updated, create a new release tag to test:

```bash
git pull origin main  # Get the updated workflow
git tag v0.1.2
git push origin v0.1.2
```

This should trigger the workflow and successfully create a release!

## What the permissions do:
- `contents: write` - Allows creating releases and uploading assets
- `packages: write` - Allows publishing packages (future-proofing)

## Alternative: Repository Settings
You can also fix this by updating repository settings:
1. Go to Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Save the changes