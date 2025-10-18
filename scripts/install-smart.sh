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

echo -e "${YELLOW}Target platform: ${OS}-${ARCH}${NC}"

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
            echo -e "${GREEN}Successfully downloaded and installed binary: $BINARY_PATH${NC}"
            exit 0
        fi
    fi
    
    rm -f "$TMP_TAR"
    echo -e "${YELLOW}Failed to extract binary from tar.gz${NC}"
fi

# Strategy 2: Try direct binary download (fallback for different release formats)
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

rm -f "$BINARY_PATH" 2>/dev/null

# Strategy 3: Build from source (last resort)
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ]; then
    if command -v go >/dev/null 2>&1; then
        echo -e "${YELLOW}Pre-built binaries not available. Building from source...${NC}"
        
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
        echo -e "${YELLOW}Please install Go and try again:${NC}"
        
        case $OS in
            darwin)
                echo -e "${YELLOW}  brew install go${NC}"
                ;;
            linux)
                echo -e "${YELLOW}  Ubuntu/Debian: sudo apt update && sudo apt install golang-go${NC}"
                echo -e "${YELLOW}  CentOS/RHEL: sudo yum install golang${NC}"
                echo -e "${YELLOW}  Arch: sudo pacman -S go${NC}"
                ;;
            *)
                echo -e "${YELLOW}  Visit: https://golang.org/dl/${NC}"
                ;;
        esac
        
        echo ""
        echo -e "${YELLOW}Or check if pre-built binaries are available at:${NC}"
        echo -e "${YELLOW}  https://github.com/bjrooney/helm-safe/releases${NC}"
        exit 1
    fi
fi

echo -e "${RED}Installation failed - no installation method available${NC}"
exit 1