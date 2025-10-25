#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing helm-safe plugin...${NC}"

# Debug: Show detection info
echo -e "${YELLOW}=== Architecture Detection Debug ===${NC}"
echo -e "${YELLOW}uname -s: $(uname -s)${NC}"
echo -e "${YELLOW}uname -m: $(uname -m)${NC}"
echo -e "${YELLOW}uname -a: $(uname -a)${NC}"
if [ -f /proc/version ]; then
    echo -e "${YELLOW}/proc/version: $(head -1 /proc/version)${NC}"
fi
if [ -f /proc/cpuinfo ]; then
    echo -e "${YELLOW}CPU info: $(grep -m1 'model name\|Hardware\|Revision' /proc/cpuinfo)${NC}"
fi
echo -e "${YELLOW}=================================${NC}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Enhanced ARM architecture detection for Raspberry Pi and mixed systems
case $ARCH in
    x86_64)
        # Check if this is actually ARM hardware being emulated
        if grep -qi "raspberry pi\|bcm283\|bcm2" /proc/cpuinfo 2>/dev/null; then
            echo -e "${YELLOW}Detected: Raspberry Pi hardware with x86_64 emulation layer${NC}"
            echo -e "${YELLOW}Forcing ARM architecture for native compatibility${NC}"
            ARCH="arm"
        elif grep -qi "armhf\|armv7" /proc/version 2>/dev/null || [ -d /lib/arm-linux-gnueabihf ]; then
            echo -e "${YELLOW}Detected: ARM userland on x86_64 system (likely container/emulation)${NC}"
            echo -e "${YELLOW}Using ARM binary for compatibility${NC}"
            ARCH="arm"
        else
            ARCH="amd64"
        fi
        ;;
    arm64|aarch64)
        # Check for mixed architecture (64-bit CPU, 32-bit userland)
        # This is common on Raspberry Pi OS 32-bit running on 64-bit hardware
        if grep -qi "armhf\|armv7" /proc/version 2>/dev/null || [ -d /lib/arm-linux-gnueabihf ]; then
            echo -e "${YELLOW}Detected: 64-bit ARM CPU with 32-bit userland (Raspberry Pi OS 32-bit)${NC}"
            echo -e "${YELLOW}Using 32-bit ARM binary for compatibility${NC}"
            ARCH="arm"
        else
            ARCH="arm64"
        fi
        ;;
    armv7l|armv7*)
        ARCH="arm"
        ;;
    armv6l|armv6*)
        ARCH="arm"
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        echo -e "${YELLOW}Supported architectures: amd64, arm64, arm (32-bit)${NC}"
        echo -e "${YELLOW}You may need to build from source if Go is available${NC}"
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
    
    # Try to download from GitHub releases (tar.gz format for better compatibility)
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
            # Check if binary was extracted correctly
            EXTRACTED_BINARY="${HELM_PLUGIN_DIR}/bin/helm-safe"
            if [ -f "$EXTRACTED_BINARY" ]; then
                echo -e "${GREEN}Downloaded and extracted binary: $EXTRACTED_BINARY${NC}"
                chmod +x "$EXTRACTED_BINARY"
                rm -f "$TMP_TAR"
                
                # Validate binary size (should be > 1MB for Go programs)
                BINARY_SIZE=$(stat -c%s "$EXTRACTED_BINARY" 2>/dev/null || echo "0")
                if [ "$BINARY_SIZE" -lt 1000000 ]; then
                    echo -e "${YELLOW}Warning: Binary seems small ($BINARY_SIZE bytes)${NC}"
                    echo -e "${YELLOW}This might indicate a download issue${NC}"
                fi
                
                exit 0
            else
                echo -e "${RED}Failed to extract binary from archive${NC}"
                rm -f "$TMP_TAR"
            fi
        else
            echo -e "${RED}Failed to extract tar.gz archive${NC}"
            rm -f "$TMP_TAR"
        fi
    fi
    
    # Fallback: try direct binary download (for older releases)
    echo -e "${YELLOW}Tar.gz download failed, trying direct binary download...${NC}"
    DIRECT_URL="https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-${OS}-${ARCH}"
    if [ "$OS" = "windows" ]; then
        DIRECT_URL="${DIRECT_URL}.exe"
    fi
    
    echo -e "${YELLOW}Downloading: ${DIRECT_URL}${NC}"
    
    DOWNLOAD_SUCCESS=false
    if command -v curl >/dev/null 2>&1; then
        if curl -sL "$DIRECT_URL" -o "$BINARY_PATH" 2>/dev/null && [ -s "$BINARY_PATH" ]; then
            DOWNLOAD_SUCCESS=true
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$DIRECT_URL" -O "$BINARY_PATH" 2>/dev/null && [ -s "$BINARY_PATH" ]; then
            DOWNLOAD_SUCCESS=true
        fi
    fi
    
    if [ "$DOWNLOAD_SUCCESS" = true ]; then
        echo -e "${GREEN}Downloaded binary: $BINARY_PATH${NC}"
        chmod +x "$BINARY_PATH"
        exit 0
    else
        echo -e "${YELLOW}Pre-built binary not available for ${OS}-${ARCH}${NC}"
        echo -e "${YELLOW}This is normal for new releases or uncommon architectures${NC}"
        rm -f "$BINARY_PATH" 2>/dev/null
        
        # ARM fallback: try alternative ARM variant
        if [ "$ARCH" = "arm" ]; then
            echo -e "${YELLOW}Trying ARM fallback: attempting armv6 variant...${NC}"
            FALLBACK_URL="https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-${OS}-armv6.tar.gz"
            TMP_TAR_FALLBACK="/tmp/helm-safe-${OS}-armv6.tar.gz"
            
            FALLBACK_SUCCESS=false
            if command -v curl >/dev/null 2>&1; then
                if curl -sL "$FALLBACK_URL" -o "$TMP_TAR_FALLBACK" 2>/dev/null && [ -s "$TMP_TAR_FALLBACK" ]; then
                    FALLBACK_SUCCESS=true
                fi
            elif command -v wget >/dev/null 2>&1; then
                if wget -q "$FALLBACK_URL" -O "$TMP_TAR_FALLBACK" 2>/dev/null && [ -s "$TMP_TAR_FALLBACK" ]; then
                    FALLBACK_SUCCESS=true
                fi
            fi
            
            if [ "$FALLBACK_SUCCESS" = true ]; then
                echo -e "${YELLOW}Extracting ARM fallback binary...${NC}"
                if tar -xzf "$TMP_TAR_FALLBACK" -C bin/ 2>/dev/null; then
                    EXTRACTED_BINARY="${HELM_PLUGIN_DIR}/bin/helm-safe"
                    if [ -f "$EXTRACTED_BINARY" ]; then
                        echo -e "${GREEN}Successfully installed ARM fallback binary: $EXTRACTED_BINARY${NC}"
                        chmod +x "$EXTRACTED_BINARY"
                        rm -f "$TMP_TAR_FALLBACK"
                        exit 0
                    fi
                fi
                rm -f "$TMP_TAR_FALLBACK"
            fi
            
            echo -e "${YELLOW}For Raspberry Pi and ARM systems:${NC}"
            echo -e "${YELLOW}  - Try installing v0.1.6+ which includes ARM support${NC}"
            echo -e "${YELLOW}  - Or install Go to build from source${NC}"
        fi
        
        echo -e "${RED}Go is required to build helm-safe from source${NC}"
        echo -e "${YELLOW}Please install Go 1.21+ and run the installation again${NC}"
        echo -e "${YELLOW}  macOS: brew install go${NC}"
        echo -e "${YELLOW}  Ubuntu/Debian: sudo apt install golang-go${NC}"
        echo -e "${YELLOW}  Raspberry Pi: sudo apt install golang-go${NC}"
        echo -e "${YELLOW}  Or visit: https://golang.org/dl/${NC}"
        exit 1
    fi
fi

echo -e "${RED}No binary found and no source code available${NC}"
echo -e "${YELLOW}For development, ensure go.mod exists in plugin directory${NC}"
echo -e "${YELLOW}For releases, binaries should be pre-built and included${NC}"
exit 1