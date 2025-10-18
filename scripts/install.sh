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

BINARY_NAME="helm-safe-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi

echo -e "${YELLOW}Target platform: ${OS}-${ARCH}${NC}"

# Create bin directory if it doesn't exist
mkdir -p "${HELM_PLUGIN_DIR}/bin"

# Check if binary already exists
BINARY_PATH="${HELM_PLUGIN_DIR}/bin/${BINARY_NAME}"
if [ -f "$BINARY_PATH" ]; then
    echo -e "${GREEN}Binary already exists at: $BINARY_PATH${NC}"
    chmod +x "$BINARY_PATH"
    exit 0
fi

# Check if we can build from source (Go is available)
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ] && command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Building from source...${NC}"
    
    cd "${HELM_PLUGIN_DIR}"
    
    # Set build variables
    VERSION=$(cat VERSION 2>/dev/null || echo "dev")
    LDFLAGS="-ldflags -X=github.com/bjrooney/helm-safe/pkg/safe.Version=${VERSION}"
    
    # Build binary
    go build $LDFLAGS -o "bin/${BINARY_NAME}" ./cmd/helm-safe
    
    echo -e "${GREEN}Built binary: bin/${BINARY_NAME}${NC}"
    chmod +x "bin/${BINARY_NAME}"
    
    exit 0
fi

# If Go is not available, try to download pre-built binary
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ] && ! command -v go >/dev/null 2>&1; then
    echo -e "${YELLOW}Go not found, attempting to download pre-built binary...${NC}"
    
    # Try to download from GitHub releases
    RELEASE_URL="https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-${OS}-${ARCH}"
    if [ "$OS" = "windows" ]; then
        RELEASE_URL="${RELEASE_URL}.exe"
    fi
    
    echo -e "${YELLOW}Downloading: ${RELEASE_URL}${NC}"
    
    DOWNLOAD_SUCCESS=false
    if command -v curl >/dev/null 2>&1; then
        if curl -sL "$RELEASE_URL" -o "$BINARY_PATH" 2>/dev/null && [ -s "$BINARY_PATH" ]; then
            DOWNLOAD_SUCCESS=true
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$RELEASE_URL" -O "$BINARY_PATH" 2>/dev/null && [ -s "$BINARY_PATH" ]; then
            DOWNLOAD_SUCCESS=true
        fi
    fi
    
    if [ "$DOWNLOAD_SUCCESS" = true ]; then
        echo -e "${GREEN}Downloaded binary: $BINARY_PATH${NC}"
        chmod +x "$BINARY_PATH"
        exit 0
    else
        echo -e "${YELLOW}Pre-built binary not available for ${OS}-${ARCH}${NC}"
        echo -e "${YELLOW}This is normal for new releases. Installing Go to build from source...${NC}"
        rm -f "$BINARY_PATH" 2>/dev/null
        
        # Check if we can install Go automatically (this is a fallback)
        echo -e "${RED}Go is required to build helm-safe from source${NC}"
        echo -e "${YELLOW}Please install Go 1.21+ and run the installation again${NC}"
        echo -e "${YELLOW}  macOS: brew install go${NC}"
        echo -e "${YELLOW}  Ubuntu/Debian: sudo apt install golang-go${NC}"
        echo -e "${YELLOW}  Or visit: https://golang.org/dl/${NC}"
        exit 1
    fi
fi

echo -e "${RED}No binary found and no source code available${NC}"
echo -e "${YELLOW}For development, ensure go.mod exists in plugin directory${NC}"
echo -e "${YELLOW}For releases, binaries should be pre-built and included${NC}"
exit 1