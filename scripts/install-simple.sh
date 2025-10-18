#!/bin/bash

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

case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

BINARY_NAME="helm-safe"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

echo -e "${YELLOW}Target platform: ${OS}-${ARCH}${NC}"

# Create bin directory if it doesn't exist
mkdir -p "${HELM_PLUGIN_DIR}/bin"

# Binary path where we want to install
BINARY_PATH="${HELM_PLUGIN_DIR}/bin/${BINARY_NAME}"

# Check if binary already exists
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN}Binary already exists at: $BINARY_PATH${NC}"
    chmod +x "$BINARY_PATH"
    exit 0
fi

# Strategy 1: Copy from platform-specific binary if it exists
PLATFORM_BINARY="${HELM_PLUGIN_DIR}/bin/helm-safe-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    PLATFORM_BINARY="${PLATFORM_BINARY}.exe"
fi

if [ -f "$PLATFORM_BINARY" ]; then
    echo -e "${GREEN}Using pre-built binary: $PLATFORM_BINARY${NC}"
    cp "$PLATFORM_BINARY" "$BINARY_PATH"
    chmod +x "$BINARY_PATH"
    exit 0
fi

# Strategy 2: Try to build from source if Go is available
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ] && command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Building from source...${NC}"
    
    cd "${HELM_PLUGIN_DIR}"
    
    # Set build variables
    VERSION=$(cat VERSION 2>/dev/null || echo "dev")
    LDFLAGS="-ldflags -X=github.com/bjrooney/helm-safe/pkg/safe.Version=${VERSION}"
    
    # Build binary
    go build $LDFLAGS -o "$BINARY_PATH" ./cmd/helm-safe
    
    echo -e "${GREEN}Built binary: $BINARY_PATH${NC}"
    chmod +x "$BINARY_PATH"
    exit 0
fi

# Strategy 3: Try to download from GitHub releases (tar.gz format)
echo -e "${YELLOW}Attempting to download pre-built binary from GitHub...${NC}"

RELEASE_URL="https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-${OS}-${ARCH}.tar.gz"

echo -e "${YELLOW}Downloading: ${RELEASE_URL}${NC}"

DOWNLOAD_SUCCESS=false
TMP_TAR="/tmp/helm-safe-${OS}-${ARCH}.tar.gz"

if command -v curl >/dev/null 2>&1; then
    if curl -sL "$RELEASE_URL" -o "$TMP_TAR" 2>/dev/null && [ -s "$TMP_TAR" ]; then
        DOWNLOAD_SUCCESS=true
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q "$RELEASE_URL" -O "$TMP_TAR" 2>/dev/null && [ -s "$TMP_TAR" ]; then
        DOWNLOAD_SUCCESS=true
    fi
fi

if [ "$DOWNLOAD_SUCCESS" = true ]; then
    echo -e "${YELLOW}Extracting binary...${NC}"
    cd "${HELM_PLUGIN_DIR}"
    
    if tar -xzf "$TMP_TAR" -C bin/ 2>/dev/null; then
        # Find the extracted binary and rename it to helm-safe
        EXTRACTED_BINARY=$(find bin/ -name "helm-safe-*" -type f | head -1)
        if [ -n "$EXTRACTED_BINARY" ] && [ -f "$EXTRACTED_BINARY" ]; then
            mv "$EXTRACTED_BINARY" "$BINARY_PATH"
            chmod +x "$BINARY_PATH"
            rm -f "$TMP_TAR"
            echo -e "${GREEN}Downloaded and installed binary: $BINARY_PATH${NC}"
            exit 0
        fi
    fi
    
    rm -f "$TMP_TAR"
    echo -e "${YELLOW}Failed to extract binary from tar.gz${NC}"
fi

# Fallback: try direct binary download (for future compatibility)
echo -e "${YELLOW}Trying direct binary download...${NC}"
DIRECT_URL="https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    DIRECT_URL="${DIRECT_URL}.exe"
fi

if command -v curl >/dev/null 2>&1; then
    if curl -sL "$DIRECT_URL" -o "$BINARY_PATH" 2>/dev/null && [ -s "$BINARY_PATH" ]; then
        echo -e "${GREEN}Downloaded binary: $BINARY_PATH${NC}"
        chmod +x "$BINARY_PATH"
        exit 0
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget -q "$DIRECT_URL" -O "$BINARY_PATH" 2>/dev/null && [ -s "$BINARY_PATH" ]; then
        echo -e "${GREEN}Downloaded binary: $BINARY_PATH${NC}"
        chmod +x "$BINARY_PATH"
        exit 0
    fi
fi

# Clean up failed downloads
rm -f "$BINARY_PATH" "$TMP_TAR" 2>/dev/null

# If all strategies failed
echo -e "${RED}Failed to install helm-safe binary${NC}"
echo -e "${YELLOW}Please try one of the following:${NC}"
echo -e "${YELLOW}1. Install Go and try again${NC}"
echo -e "${YELLOW}2. Download the binary manually from GitHub releases${NC}"
echo -e "${YELLOW}3. Build locally and copy to: $BINARY_PATH${NC}"
exit 1