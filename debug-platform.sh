#!/bin/bash

# Debug script to understand the platform detection and binary issues

echo "=== Platform Detection Debug ==="
echo "uname -s: $(uname -s)"
echo "uname -m: $(uname -m)"
echo "uname -a: $(uname -a)"

# Check what our detection logic produces
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

echo "Detected OS: $OS"
echo "Raw ARCH: $ARCH"

case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="arm"
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        ;;
esac

echo "Mapped ARCH: $ARCH"
echo "Target binary: helm-safe-${OS}-${ARCH}"

# Check if the binary exists and its properties
BINARY_PATH="$HOME/.local/share/helm/plugins/helm-safe/bin/helm-safe"
if [ -f "$BINARY_PATH" ]; then
    echo ""
    echo "=== Binary Analysis ==="
    echo "Binary exists at: $BINARY_PATH"
    echo "File info:"
    file "$BINARY_PATH" 2>/dev/null || echo "file command not available"
    echo "Permissions:"
    ls -la "$BINARY_PATH"
    echo "Is executable:"
    test -x "$BINARY_PATH" && echo "Yes" || echo "No"
    
    echo ""
    echo "=== Attempting to check binary type ==="
    if command -v objdump >/dev/null 2>&1; then
        objdump -f "$BINARY_PATH" 2>/dev/null | head -5
    elif command -v readelf >/dev/null 2>&1; then
        readelf -h "$BINARY_PATH" 2>/dev/null | grep -E "(Class|Machine)"
    else
        echo "No binary analysis tools available"
    fi
else
    echo "Binary not found at: $BINARY_PATH"
fi

echo ""
echo "=== System Architecture Details ==="
if [ -f /proc/cpuinfo ]; then
    echo "CPU info:"
    grep -E "(model name|Hardware|Revision)" /proc/cpuinfo | head -3
fi

echo ""
echo "=== Go Architecture Detection ==="
if command -v go >/dev/null 2>&1; then
    echo "GOOS: $(go env GOOS)"
    echo "GOARCH: $(go env GOARCH)"
fi