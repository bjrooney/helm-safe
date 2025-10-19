#!/bin/bash

# Smart installation script that prioritizes pre-built binaries over building from source
# This provides the best user experience for most users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing helm-safe plugin...${NC}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
GOARM=""

# Special handling for Raspberry Pi and mixed architecture systems
if [ "$OS" = "linux" ] && [ "$ARCH" = "aarch64" ] && [ -f /proc/version ]; then
    # Check if this is actually a 32-bit userland on 64-bit hardware
    if grep -qi "armhf\|armv7" /proc/version || [ -d /lib/arm-linux-gnueabihf ]; then
        echo -e "${YELLOW}Detected 64-bit ARM CPU with 32-bit userland (common on Raspberry Pi)${NC}"
        ARCH="arm"
    fi
fi

case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    armv7l|armv7*)
        ARCH="arm"
        GOARM="7"
        echo -e "${YELLOW}Note: Detected 32-bit ARM (armv7). If this fails, you may need to build from source.${NC}"
        ;;
    armv6l|armv6*)
        ARCH="arm"
        GOARM="6"
        echo -e "${YELLOW}Note: Detected 32-bit ARM (armv6). If this fails, you may need to build from source.${NC}"
        ;;
    arm)
        # Already set correctly, default to 7 if GOARM is not set
        if [ -z "$GOARM" ]; then
            GOARM="7"
        fi
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        echo -e "${YELLOW}Supported: x86_64, arm64, armv7l, armv6l${NC}"
        exit 1
        ;;
esac

# Construct platform string
PLATFORM="${OS}-${ARCH}"
if [ "$ARCH" = "arm" ] && [ -n "$GOARM" ]; then
    # Use armv6 build for GOARM=6
    if [ "$GOARM" = "6" ]; then
        PLATFORM="${OS}-armv6"
    fi
fi

echo -e "${YELLOW}Target platform: ${PLATFORM}${NC}"

# Create bin directory
mkdir -p "${HELM_PLUGIN_DIR}/bin"
BINARY_PATH="${HELM_PLUGIN_DIR}/bin/helm-safe"

# Check if binary already exists
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN}Binary already exists at: $BINARY_PATH${NC}"
    chmod +x "$BINARY_PATH"
    exit 0
fi

# Strategy 1: Try to download pre-built binary from GitHub releases (tar.gz format)
echo -e "${YELLOW}Attempting to download pre-built binary...${NC}"

RELEASE_URL="https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-${PLATFORM}.tar.gz"
echo -e "${YELLOW}Downloading: ${RELEASE_URL}${NC}"

DOWNLOAD_SUCCESS=false
TMP_TAR="/tmp/helm-safe-${PLATFORM}.tar.gz"

# Clean up previous temp file if it exists
rm -f "$TMP_TAR"

if command -v curl >/dev/null 2>&1; then
    if curl -sL "$RELEASE_URL" -o "$TMP_TAR" 2>/dev/null && [ -s "$TMP_TAR" ]; then
        DOWNLOAD_SUCCESS=true
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q "$RELEASE_URL" -O "$TMP_TAR" && [ -s "$TMP_TAR" ]; then
        DOWNLOAD_SUCCESS=true
    fi
fi

if [ "$DOWNLOAD_SUCCESS" = true ]; then
    echo -e "${YELLOW}Extracting binary...${NC}"
    cd "${HELM_PLUGIN_DIR}"
    
    if tar -xzf "$TMP_TAR" -C bin/; then
        # Check if the binary was extracted to the expected path
        if [ -f "$BINARY_PATH" ]; then
            chmod +x "$BINARY_PATH"
            
            # Verify the binary works and has reasonable size
            case $(uname -s) in
                Darwin)
                    BINARY_SIZE=$(stat -f %z "$BINARY_PATH" 2>/dev/null || echo "0")
                    ;;
                *)
                    BINARY_SIZE=$(stat -c%s "$BINARY_PATH" 2>/dev/null || echo "0")
                    ;;
            esac

            if [ "$BINARY_SIZE" -lt 1000000 ]; then  # Less than 1MB is suspicious for a Go binary
                echo -e "${YELLOW}Warning: Binary size ($BINARY_SIZE bytes) seems too small. May be corrupted.${NC}"
                rm -f "$BINARY_PATH"
            elif "$BINARY_PATH" --version >/dev/null 2>&1 || "$BINARY_PATH" --help >/dev/null 2>&1; then
                echo -e "${GREEN}Successfully downloaded and installed binary: $BINARY_PATH${NC}"
                rm -f "$TMP_TAR"
                exit 0
            else
                echo -e "${YELLOW}Downloaded binary appears corrupted or incompatible (exec format error)${NC}"
                echo -e "${YELLOW}Your system: $(uname -a)${NC}"
                echo -e "${YELLOW}Binary: $(file "$BINARY_PATH" 2>/dev/null || echo "file command not available")${NC}"
                rm -f "$BINARY_PATH"
            fi
        fi
    fi
    
    rm -f "$TMP_TAR"
    echo -e "${YELLOW}Failed to extract or verify binary from tar.gz${NC}"
fi

# Strategy 2: Build from source (last resort)
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ]; then
    if command -v go >/dev/null 2>&1; then
        echo -e "${YELLOW}Pre-built binaries not available or incompatible. Building from source...${NC}"
        
        cd "${HELM_PLUGIN_DIR}"
        
        # Set build variables
        VERSION=$(cat VERSION 2>/dev/null || echo "dev")
        LDFLAGS="-ldflags -X=github.com/bjrooney/helm-safe/pkg/safe.Version=${VERSION}"
        
        # Build binary
        if go build $LDFLAGS -o "$BINARY_PATH" ./cmd/helm-safe; then
            echo -e "${GREEN}Successfully built binary: $BINARY_PATH${NC}"
            chmod +x "$BINARY_PATH"
            exit 0
        else
            echo -e "${RED}Failed to build from source${NC}"
        fi
    else
        echo -e "${YELLOW}Pre-built binaries not available and Go not found.${NC}"
        echo -e "${RED}Installation failed${NC}"
        echo ""
        echo -e "${YELLOW}Please install Go and try again, or download a binary manually from:${NC}"
        echo -e "${YELLOW}  https://github.com/bjrooney/helm-safe/releases${NC}"
        exit 1
    fi
fi

echo -e "${RED}Installation failed - no installation method available${NC}"
exit 1
