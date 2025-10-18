#!/bin/bash

# Temporary installation script that prioritizes building from source
# This works around the missing GitHub release binaries

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing helm-safe plugin (build-first strategy)...${NC}"

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

# Strategy 1: Build from source (preferred for now)
if [ -f "${HELM_PLUGIN_DIR}/go.mod" ]; then
    if command -v go >/dev/null 2>&1; then
        echo -e "${YELLOW}Building from source...${NC}"
        
        cd "${HELM_PLUGIN_DIR}"
        
        # Set build variables
        VERSION=$(cat VERSION 2>/dev/null || echo "0.1.0")
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
        echo -e "${YELLOW}Go not found. Attempting to install Go...${NC}"
        
        # Suggest Go installation
        case $OS in
            darwin)
                echo -e "${YELLOW}Install Go with: brew install go${NC}"
                ;;
            linux)
                echo -e "${YELLOW}Install Go with:${NC}"
                echo -e "${YELLOW}  Ubuntu/Debian: sudo apt update && sudo apt install golang-go${NC}"
                echo -e "${YELLOW}  CentOS/RHEL: sudo yum install golang${NC}"
                echo -e "${YELLOW}  Arch: sudo pacman -S go${NC}"
                ;;
            *)
                echo -e "${YELLOW}Install Go from: https://golang.org/dl/${NC}"
                ;;
        esac
        
        echo -e "${RED}Go is required to build helm-safe from source${NC}"
        echo -e "${YELLOW}After installing Go, run the installation again${NC}"
        exit 1
    fi
fi

echo -e "${RED}Installation failed${NC}"
echo -e "${YELLOW}This plugin requires Go to build from source${NC}"
exit 1