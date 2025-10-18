#!/bin/bash

set -e

# helm-safe installation script
# Usage: curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Plugin information
PLUGIN_NAME="helm-safe"
PLUGIN_REPO="bjrooney/helm-safe"
PLUGIN_URL="https://github.com/${PLUGIN_REPO}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Helm Safe Plugin Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if helm is installed
if ! command -v helm >/dev/null 2>&1; then
    echo -e "${RED}Error: helm is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install Helm first: https://helm.sh/docs/intro/install/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Helm found: $(helm version --short)${NC}"

# Check if plugin is already installed
if helm plugin list | grep -q "^${PLUGIN_NAME}"; then
    echo -e "${YELLOW}⚠ helm-safe plugin is already installed${NC}"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Uninstalling existing plugin...${NC}"
        helm plugin uninstall helm-safe
    else
        echo -e "${GREEN}Installation cancelled. Plugin already exists.${NC}"
        exit 0
    fi
fi

# Detect OS and architecture
echo -e "${YELLOW}Detecting system...${NC}"
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
        echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
        echo -e "${YELLOW}Supported architectures: amd64, arm64${NC}"
        exit 1
        ;;
esac

case $OS in
    linux|darwin)
        ;;
    mingw*|msys*|cygwin*)
        OS="windows"
        ;;
    *)
        echo -e "${RED}Error: Unsupported operating system: $OS${NC}"
        echo -e "${YELLOW}Supported systems: Linux, macOS, Windows${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Detected platform: ${OS}-${ARCH}${NC}"

# Install via helm plugin install (preferred method)
echo ""
echo -e "${YELLOW}Installing helm-safe plugin...${NC}"
echo -e "${BLUE}Running: helm plugin install ${PLUGIN_URL}${NC}"

# Note: The plugin's own install scripts will handle binary building/downloading
if helm plugin install "${PLUGIN_URL}"; then
    echo ""
    echo -e "${GREEN}🎉 helm-safe plugin installed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Quick start:${NC}"
    echo -e "${YELLOW}  helm safe status${NC}              # Check current context and namespace"
    echo -e "${YELLOW}  helm safe install myapp ./chart${NC} # Safe install with confirmation"
    echo -e "${YELLOW}  helm safe --help${NC}                 # Show all available commands"
    echo ""
    echo -e "${BLUE}The plugin will:${NC}"
    echo -e "  • Show current context and namespace before any operation"
    echo -e "  • Require confirmation for modifying commands (install, upgrade, delete)"
    echo -e "  • Pass through safe commands (list, status, get) without confirmation"
    echo -e "  • Allow bypassing with --force flag when needed"
    echo ""
    echo -e "${GREEN}For more information: ${PLUGIN_URL}${NC}"
else
    echo ""
    echo -e "${RED}❌ Failed to install helm-safe plugin${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "1. Check your internet connection"
    echo -e "2. Verify Helm is properly installed and in PATH"
    echo -e "3. Try manual installation:"
    echo -e "   ${BLUE}helm plugin install ${PLUGIN_URL}${NC}"
    echo ""
    echo -e "${YELLOW}If you're behind a proxy or firewall:${NC}"
    echo -e "1. Download the plugin manually:"
    echo -e "   ${BLUE}git clone ${PLUGIN_URL} ~/.local/share/helm/plugins/helm-safe${NC}"
    echo -e "2. Install dependencies and build (if needed)"
    echo ""
    echo -e "${YELLOW}For support, please visit: ${PLUGIN_URL}/issues${NC}"
    exit 1
fi

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"
if helm plugin list | grep -q "^${PLUGIN_NAME}"; then
    PLUGIN_VERSION=$(helm plugin list | grep "^${PLUGIN_NAME}" | awk '{print $2}')
    echo -e "${GREEN}✓ Plugin verification successful${NC}"
    echo -e "${GREEN}✓ Version: ${PLUGIN_VERSION}${NC}"
    
    # Test basic functionality
    echo -e "${YELLOW}Testing basic functionality...${NC}"
    if helm safe --help >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Plugin is working correctly${NC}"
    else
        echo -e "${YELLOW}⚠ Plugin installed but may not be working correctly${NC}"
        echo -e "${YELLOW}Try running: helm safe --help${NC}"
    fi
else
    echo -e "${RED}❌ Plugin verification failed${NC}"
    echo -e "${YELLOW}The plugin may not have installed correctly${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 Installation complete! Happy Helm-ing safely! 🚀${NC}"
echo ""