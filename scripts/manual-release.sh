#!/bin/bash

# Script to manually create a GitHub release when Actions fail
# This creates the release structure that would be created by GitHub Actions

set -e

# Check if gh CLI is available
if ! command -v gh >/dev/null 2>&1; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "📥 Install it from: https://cli.github.com/"
    echo ""
    echo "Alternative: Create release manually at:"
    echo "🌐 https://github.com/bjrooney/helm-safe/releases/new"
    exit 1
fi

# Check if we're authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "🔐 Run: gh auth login"
    exit 1
fi

VERSION="0.1.1"
TAG="v${VERSION}"

echo "🚀 Creating GitHub release for ${TAG}..."

# Check if tag exists
if ! git tag | grep -q "^${TAG}$"; then
    echo "❌ Tag ${TAG} not found locally"
    echo "📋 Available tags:"
    git tag
    exit 1
fi

# Build binaries locally
echo "🔨 Building binaries..."
if ! make cross-build; then
    echo "❌ Build failed"
    exit 1
fi

# Create distribution directory
mkdir -p dist
echo "📦 Creating packages..."

# Package binaries
for binary in bin/helm-safe-*; do
    if [[ "$binary" == *".exe" ]]; then
        # Windows binary
        platform=$(basename "$binary" .exe | sed 's/helm-safe-//')
        tar czf "dist/helm-safe-${platform}.tar.gz" -C bin "$(basename "$binary")"
        echo "✅ Created helm-safe-${platform}.tar.gz"
    else
        # Unix binary
        platform=$(basename "$binary" | sed 's/helm-safe-//')
        tar czf "dist/helm-safe-${platform}.tar.gz" -C bin "$(basename "$binary")"
        echo "✅ Created helm-safe-${platform}.tar.gz"
    fi
done

# Create release notes
RELEASE_NOTES="# helm-safe ${TAG}

Initial release of the helm-safe Helm plugin.

## Features
- Interactive safety net for modifying Helm commands
- Requires explicit --namespace and --kube-context flags
- Shows confirmation prompts for destructive operations
- Transparent pass-through for safe commands

## Installation

\`\`\`bash
# Quick install
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash

# Or via Helm plugin
helm plugin install https://github.com/bjrooney/helm-safe
\`\`\`

## Supported Platforms
- Linux (amd64, arm64)
- macOS (amd64, arm64)  
- Windows (amd64)

## Usage
\`\`\`bash
# Replace dangerous commands with safe versions
helm safe install myapp ./chart --namespace myapp --kube-context dev-cluster

# Safe commands pass through without confirmation
helm safe list --all-namespaces
\`\`\`"

# Create the release
echo "🎯 Creating GitHub release..."
if gh release create "${TAG}" dist/*.tar.gz \
    --title "helm-safe ${TAG}" \
    --notes "${RELEASE_NOTES}"; then
    echo "🎉 Successfully created release ${TAG}!"
    echo "🌐 View at: https://github.com/bjrooney/helm-safe/releases/tag/${TAG}"
else
    echo "❌ Failed to create release"
    echo "💡 Try creating manually at: https://github.com/bjrooney/helm-safe/releases/new"
    echo "📁 Upload files from: dist/"
    ls -la dist/
fi