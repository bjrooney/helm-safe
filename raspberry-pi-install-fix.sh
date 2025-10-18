#!/bin/bash

# Raspberry Pi Installation Fix Script for helm-safe
# This script handles the specific installation issues on Raspberry Pi systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍓 Raspberry Pi helm-safe Installation Fix${NC}"
echo "============================================"

# Function to clean up corrupted installation
cleanup_installation() {
    echo -e "${YELLOW}🧹 Cleaning up corrupted installation...${NC}"
    
    # Try multiple ways to remove the plugin
    helm plugin uninstall safe 2>/dev/null || true
    
    # Manual cleanup if helm uninstall fails
    PLUGIN_DIR="$HOME/.local/share/helm/plugins/helm-safe"
    if [ -d "$PLUGIN_DIR" ]; then
        echo -e "${YELLOW}Manually removing plugin directory...${NC}"
        rm -rf "$PLUGIN_DIR" 2>/dev/null || {
            echo -e "${YELLOW}Permission issue, trying with sudo...${NC}"
            sudo rm -rf "$PLUGIN_DIR" 2>/dev/null || {
                echo -e "${RED}Failed to remove $PLUGIN_DIR${NC}"
                echo -e "${YELLOW}Please manually remove it: rm -rf $PLUGIN_DIR${NC}"
                exit 1
            }
        }
    fi
    
    # Also check alternative locations
    ALT_PLUGIN_DIR="$HOME/.helm/plugins/helm-safe"
    if [ -d "$ALT_PLUGIN_DIR" ]; then
        echo -e "${YELLOW}Removing from alternative location...${NC}"
        rm -rf "$ALT_PLUGIN_DIR" 2>/dev/null || sudo rm -rf "$ALT_PLUGIN_DIR" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Function to detect architecture properly
detect_architecture() {
    local arch=$(uname -m)
    local detected_arch=""
    
    echo -e "${BLUE}🔍 Detecting system architecture...${NC}"
    echo "  Raw architecture: $arch"
    
    case $arch in
        x86_64)
            detected_arch="amd64"
            ;;
        aarch64)
            # Check for mixed architecture (64-bit CPU, 32-bit userland)
            if grep -qi "armhf\|armv7" /proc/version 2>/dev/null || [ -d /lib/arm-linux-gnueabihf ]; then
                echo -e "${YELLOW}  Detected: 64-bit ARM CPU with 32-bit userland (Raspberry Pi OS 32-bit)${NC}"
                detected_arch="arm"
            else
                echo -e "${BLUE}  Detected: 64-bit ARM (native)${NC}"
                detected_arch="arm64"
            fi
            ;;
        armv7l|armv7*)
            echo -e "${BLUE}  Detected: 32-bit ARM (armv7)${NC}"
            detected_arch="arm"
            ;;
        armv6l|armv6*)
            echo -e "${BLUE}  Detected: 32-bit ARM (armv6)${NC}"
            detected_arch="arm"
            ;;
        arm64)
            detected_arch="arm64"
            ;;
        *)
            echo -e "${RED}  Unknown architecture: $arch${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}  Target architecture: $detected_arch${NC}"
    echo "$detected_arch"
}

# Function to install from source with Go
install_from_source() {
    echo -e "${YELLOW}🔨 Installing from source...${NC}"
    
    # Check if Go is available
    if ! command -v go >/dev/null 2>&1; then
        echo -e "${RED}Go not found. Installing Go...${NC}"
        
        # Install Go on Raspberry Pi
        if command -v apt >/dev/null 2>&1; then
            echo -e "${YELLOW}Installing Go via apt...${NC}"
            sudo apt update
            sudo apt install -y golang-go
        elif command -v yum >/dev/null 2>&1; then
            echo -e "${YELLOW}Installing Go via yum...${NC}"
            sudo yum install -y golang
        else
            echo -e "${RED}Cannot install Go automatically. Please install manually:${NC}"
            echo -e "${YELLOW}  https://golang.org/dl/${NC}"
            exit 1
        fi
    fi
    
    # Clone and build
    TEMP_DIR="/tmp/helm-safe-build-$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/bjrooney/helm-safe.git .
    
    echo -e "${YELLOW}Building binary...${NC}"
    go mod download
    go build -ldflags "-X github.com/bjrooney/helm-safe/pkg/safe.Version=$(cat VERSION)" -o helm-safe ./cmd/helm-safe
    
    # Install using helm plugin install from local directory
    echo -e "${YELLOW}Installing plugin...${NC}"
    helm plugin install "$TEMP_DIR"
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}✅ Installed from source successfully${NC}"
}

# Function to try different download methods
try_download_binary() {
    local arch="$1"
    local os="linux"
    
    echo -e "${YELLOW}📦 Attempting to download pre-built binary...${NC}"
    
    # Try different release versions
    local versions=("latest" "v0.1.9" "v0.1.8" "v0.1.7")
    
    for version in "${versions[@]}"; do
        echo -e "${BLUE}Trying version: $version${NC}"
        
        # Try tar.gz format first
        local url="https://github.com/bjrooney/helm-safe/releases/$version/download/helm-safe-${os}-${arch}.tar.gz"
        echo -e "${YELLOW}  Trying: $url${NC}"
        
        if curl -sL --fail "$url" -o "/tmp/helm-safe-${os}-${arch}.tar.gz" 2>/dev/null; then
            # Verify it's actually a tar.gz file
            if file "/tmp/helm-safe-${os}-${arch}.tar.gz" 2>/dev/null | grep -q "gzip compressed"; then
                echo -e "${GREEN}  ✅ Downloaded tar.gz successfully${NC}"
                
                # Create temporary plugin directory
                TEMP_PLUGIN_DIR="/tmp/helm-safe-plugin-$$"
                mkdir -p "$TEMP_PLUGIN_DIR"
                cd "$TEMP_PLUGIN_DIR"
                
                # Extract and verify
                if tar -xzf "/tmp/helm-safe-${os}-${arch}.tar.gz" 2>/dev/null; then
                    if [ -f "helm-safe" ] && [ -x "helm-safe" ]; then
                        # Test the binary
                        if ./helm-safe --version >/dev/null 2>&1; then
                            echo -e "${GREEN}  ✅ Binary verified and working${NC}"
                            
                            # Download plugin.yaml and other files
                            curl -sL "https://raw.githubusercontent.com/bjrooney/helm-safe/main/plugin.yaml" -o plugin.yaml
                            curl -sL "https://raw.githubusercontent.com/bjrooney/helm-safe/main/README.md" -o README.md
                            
                            # Create bin directory and move binary
                            mkdir -p bin
                            mv helm-safe bin/
                            
                            # Install using helm plugin install from local directory
                            echo -e "${YELLOW}Installing plugin...${NC}"
                            helm plugin install "$TEMP_PLUGIN_DIR"
                            
                            # Cleanup
                            cd /
                            rm -rf "$TEMP_PLUGIN_DIR"
                            rm -f "/tmp/helm-safe-${os}-${arch}.tar.gz"
                            
                            echo -e "${GREEN}✅ Installation successful!${NC}"
                            return 0
                        else
                            echo -e "${RED}  ❌ Binary not executable or corrupted${NC}"
                        fi
                    else
                        echo -e "${RED}  ❌ Binary not found in archive${NC}"
                    fi
                else
                    echo -e "${RED}  ❌ Failed to extract archive${NC}"
                fi
                
                # Cleanup failed attempt
                cd /
                rm -rf "$TEMP_PLUGIN_DIR"
            else
                echo -e "${RED}  ❌ Downloaded file is not a valid tar.gz${NC}"
            fi
            
            rm -f "/tmp/helm-safe-${os}-${arch}.tar.gz"
        else
            echo -e "${RED}  ❌ Download failed${NC}"
        fi
    done
    
    return 1
}

# Main installation function
main() {
    echo -e "${BLUE}Starting Raspberry Pi installation fix...${NC}"
    
    # Step 1: Clean up any corrupted installation
    cleanup_installation
    
    # Step 2: Detect architecture
    local arch
    arch=$(detect_architecture)
    
    # Step 3: Try to download binary
    if try_download_binary "$arch"; then
        echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    else
        echo -e "${YELLOW}Binary download failed, trying source installation...${NC}"
        install_from_source
    fi
    
    # Step 4: Verify installation
    echo -e "${BLUE}🧪 Testing installation...${NC}"
    if helm plugin list | grep -q "safe"; then
        echo -e "${GREEN}✅ Plugin installed successfully${NC}"
        if helm safe --version >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Plugin working correctly${NC}"
            helm safe --version
        else
            echo -e "${YELLOW}⚠️  Plugin installed but not responding correctly${NC}"
        fi
    else
        echo -e "${RED}❌ Plugin installation verification failed${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 helm-safe installation complete!${NC}"
    echo ""
    echo -e "${BLUE}Quick start:${NC}"
    echo -e "  helm safe status              # Check current context"
    echo -e "  helm safe install app ./chart # Safe install with confirmation"
    echo -e "  helm safe --help              # Show all commands"
}

# Run main function
main "$@"