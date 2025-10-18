#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing helm-safe plugin (with tar.gz support)...${NC}"

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

BINARY_NAME="helm-safe-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

echo -e "${YELLOW}Target platform: ${OS}-${ARCH}${NC}"

# Create bin directory if it doesn't exist
mkdir -p "${HELM_PLUGIN_DIR}/bin"

# Check if binary already exists
BINARY_PATH="${HELM_PLUGIN_DIR}/bin/helm-safe"
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN}Binary already exists at: $BINARY_PATH${NC}"
    chmod +x "$BINARY_PATH"
    exit 0
fi

# Try building from source first (if Go is available)
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ] && command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Building from source...${NC}"
    
    cd "${HELM_PLUGIN_DIR}"
    
    # Set build variables
    VERSION=$(cat VERSION 2>/dev/null || echo "dev")
    LDFLAGS="-ldflags -X=github.com/bjrooney/helm-safe/pkg/safe.Version=${VERSION}"
    
    # Build binary
    go build $LDFLAGS -o "bin/helm-safe" ./cmd/helm-safe
    
    echo -e "${GREEN}Built binary: bin/helm-safe${NC}"
    chmod +x "bin/helm-safe"
    
    exit 0
fi

# If Go is not available, try to download and extract tar.gz
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ] && ! command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Go not found, attempting to download pre-built binary...${NC}"
    
    # Try to download tar.gz from GitHub releases
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
                mv "$EXTRACTED_BINARY" "bin/helm-safe"
                chmod +x "bin/helm-safe"
                rm -f "$TMP_TAR"
                echo -e "${GREEN}Installed binary: bin/helm-safe${NC}"
                exit 0
            fi
        fi
        
        rm -f "$TMP_TAR"
        echo -e "${YELLOW}Failed to extract binary from tar.gz${NC}"
    else
        echo -e "${YELLOW}Pre-built binary not available for ${OS}-${ARCH}${NC}"
        rm -f "$TMP_TAR" 2>/dev/null
    fi
    
    echo -e "${YELLOW}This is normal for new releases. Go is required to build from source.${NC}"
    echo -e "${RED}Go is required to build helm-safe from source${NC}"
    echo -e "${YELLOW}Please install Go 1.21+ and run the installation again${NC}"
    echo -e "${YELLOW}  macOS: brew install go${NC}"
    echo -e "${YELLOW}  Ubuntu/Debian: sudo apt install golang-go${NC}"
    echo -e "${YELLOW}  Or visit: https://golang.org/dl/${NC}"
    exit 1
fi

echo -e "${RED}No binary found and no source code available${NC}"
echo -e "${YELLOW}For development, ensure go.mod exists in plugin directory${NC}"
echo -e "${YELLOW}For releases, binaries should be pre-built and included${NC}"
exit 1