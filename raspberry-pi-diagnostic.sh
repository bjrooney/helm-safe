#!/bin/bash

# Quick diagnostic for Raspberry Pi helm-safe installation issues
# Run this to diagnose the exec format error

echo "🔍 Raspberry Pi helm-safe Diagnostic"
echo "===================================="

echo ""
echo "📋 System Information:"
echo "  OS: $(uname -s)"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo "  Platform: $(uname -a)"

if [ -f /proc/cpuinfo ]; then
    echo ""
    echo "🖥️  CPU Information:"
    grep -E "(model name|Hardware|Revision)" /proc/cpuinfo | head -3
fi

echo ""
echo "🔧 Current Binary Status:"
BINARY_PATH="$HOME/.local/share/helm/plugins/helm-safe/bin/helm-safe"
if [ -f "$BINARY_PATH" ]; then
    echo "  Binary exists: ✅"
    echo "  Path: $BINARY_PATH"
    BINARY_SIZE=$(stat -c%s "$BINARY_PATH" 2>/dev/null || echo "unknown")
    echo "  Size: $(du -h "$BINARY_PATH" | cut -f1) ($BINARY_SIZE bytes)"
    echo "  Permissions: $(ls -la "$BINARY_PATH" | awk '{print $1}')"
    
    # Check if size is suspicious
    if [ "$BINARY_SIZE" != "unknown" ] && [ "$BINARY_SIZE" -lt 1000000 ]; then
        echo "  ⚠️  Size warning: Binary seems too small for a Go program (< 1MB)"
        echo "     This suggests a corrupted or incomplete download"
    fi
    
    if command -v file >/dev/null 2>&1; then
        echo "  File type: $(file "$BINARY_PATH")"
    fi
    
    echo ""
    echo "🧪 Testing Binary:"
    if "$BINARY_PATH" --help >/dev/null 2>&1; then
        echo "  Binary test: ✅ Working"
    else
        echo "  Binary test: ❌ Failed (exec format error likely)"
        echo "  This confirms architecture mismatch or corrupted binary"
    fi
else
    echo "  Binary exists: ❌"
    echo "  Expected path: $BINARY_PATH"
fi

echo ""
echo "🎯 Recommended Action:"
ARCH=$(uname -m)
NEEDS_32BIT=""

# Check for mixed architecture (64-bit CPU, 32-bit userland)
if [ "$ARCH" = "aarch64" ]; then
    if grep -qi "armhf\|armv7" /proc/version 2>/dev/null || [ -d /lib/arm-linux-gnueabihf ]; then
        NEEDS_32BIT="true"
        echo "  Your system: 64-bit ARM CPU with 32-bit userland (Raspberry Pi OS 32-bit)"
        echo "  🔧 This requires 32-bit ARM binaries, not 64-bit ARM binaries"
        echo "  ✅ Try installing v0.1.6+ which includes 32-bit ARM support"
    else
        echo "  Your system: 64-bit ARM (native)"
        echo "  🔄 The current binary should work. Try reinstalling."
    fi
else
    case $ARCH in
        armv7l|armv7*)
            echo "  Your system: 32-bit ARM (armv7)"
            echo "  ✅ Try installing v0.1.6+ which includes 32-bit ARM support"
            ;;
        armv6l|armv6*)
            echo "  Your system: 32-bit ARM (armv6)"  
            echo "  ✅ Try installing v0.1.6+ which includes 32-bit ARM support"
            ;;
        arm64)
            echo "  Your system: 64-bit ARM"
            echo "  🔄 The current binary should work. Try reinstalling."
            ;;
        *)
            echo "  Your system: $ARCH"
            echo "  ❓ Unknown architecture. May need to build from source."
            ;;
    esac
fi

echo ""
echo "🚀 Installation Commands:"
echo "  # Uninstall current plugin:"
echo "  helm plugin uninstall safe"
echo ""
echo "  # Install latest version (v0.1.6+):"
echo "  curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/quick-install.sh | bash"
echo ""
echo "  # Or install with Go (if available):"
echo "  helm plugin install https://github.com/bjrooney/helm-safe"