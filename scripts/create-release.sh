#!/bin/bash

# Manual release creation script
# This creates the same files that GitHub Actions would create

set -e

VERSION="0.1.0"
BUILD_DIR="bin"
DIST_DIR="dist"

echo "Creating release artifacts for version $VERSION..."

# Create dist directory
mkdir -p "$DIST_DIR"

# Build all platforms
echo "Building for all platforms..."
make cross-build

# Create tar.gz files for each platform
echo "Creating release packages..."

for binary in $BUILD_DIR/helm-safe-*; do
    if [[ "$binary" == *".exe" ]]; then
        # Windows binary
        platform=$(basename "$binary" .exe | sed 's/helm-safe-//')
        echo "Packaging $platform (Windows)..."
        tar czf "$DIST_DIR/helm-safe-${platform}.tar.gz" -C "$BUILD_DIR" "$(basename "$binary")"
        # Also copy the binary directly
        cp "$binary" "$DIST_DIR/"
    else
        # Unix binary
        platform=$(basename "$binary" | sed 's/helm-safe-//')
        echo "Packaging $platform..."
        tar czf "$DIST_DIR/helm-safe-${platform}.tar.gz" -C "$BUILD_DIR" "$(basename "$binary")"
        # Also copy the binary directly
        cp "$binary" "$DIST_DIR/"
    fi
done

echo "Release artifacts created in $DIST_DIR/:"
ls -la "$DIST_DIR/"

echo ""
echo "To create a GitHub release:"
echo "1. Go to https://github.com/bjrooney/helm-safe/releases/new"
echo "2. Tag: v$VERSION"
echo "3. Title: helm-safe v$VERSION"
echo "4. Upload all files from $DIST_DIR/"
echo ""
echo "Or use GitHub CLI:"
echo "gh release create v$VERSION $DIST_DIR/* --title 'helm-safe v$VERSION' --notes 'Initial release of helm-safe plugin'"