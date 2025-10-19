#!/bin/bash

set -e

# helm-safe comprehensive installation script
# Usage: curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash
#        helm plugin install https://github.com/bjrooney/helm-safe

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Plugin information
PLUGIN_NAME="helm-safe"
PLUGIN_REPO="bjrooney/helm-safe"
PLUGIN_URL="https://github.com/${PLUGIN_REPO}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    🛡️  Helm Safe Plugin Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to detect hardware details (integrated from go-extended script)
detect_hardware_details() {
    local os_kernel=$(uname -s)
    local hw_arch=$(uname -m)
    local hw_supplier="Unknown"
    local hw_model="Unknown"
    
    echo -e "${CYAN}🔍 Hardware Detection${NC}"
    echo "--------------------------------------------"
    
    # Detect hardware supplier and model
    case "$os_kernel" in
        Darwin)
            hw_supplier="Apple"
            if command -v system_profiler >/dev/null 2>&1; then
                model_name=$(system_profiler SPHardwareDataType 2>/dev/null | awk -F: '/Model Name/ {print $2}' | sed 's/^ *//' | head -1)
                model_id=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
                hw_model="$model_name ($model_id)"
            fi
            ;;
        Linux)
            # Raspberry Pi Device Tree check (most specific)
            if [ -f /sys/firmware/devicetree/base/model ]; then
                hw_supplier="Raspberry Pi Foundation"
                hw_model=$(tr -d '\0' < /sys/firmware/devicetree/base/model 2>/dev/null || echo "Raspberry Pi")
            # Android check
            elif command -v getprop >/dev/null 2>&1; then
                hw_supplier=$(getprop ro.product.manufacturer 2>/dev/null || echo "Android Device")
                hw_model=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
            # Standard PC/Server DMI/SMBIOS
            elif [ -d /sys/class/dmi/id/ ]; then
                if [ -f /sys/class/dmi/id/sys_vendor ]; then
                    hw_supplier=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null | sed 's/^ *//g;s/ *$//g' || echo "Unknown")
                fi
                if [ -f /sys/class/dmi/id/product_name ]; then
                    hw_model=$(cat /sys/class/dmi/id/product_name 2>/dev/null | sed 's/^ *//g;s/ *$//g' || echo "Unknown")
                fi
            # Fallback to CPU info
            elif [ -f /proc/cpuinfo ]; then
                hw_supplier=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^ *//' 2>/dev/null || echo "Unknown")
                hw_model=$(grep -m 1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^ *//' 2>/dev/null || echo "Unknown")
            fi
            ;;
    esac
    
    echo -e "  ${PURPLE}Supplier:${NC}         $hw_supplier"
    echo -e "  ${PURPLE}Model:${NC}            $hw_model"
    echo -e "  ${PURPLE}OS Kernel:${NC}        $os_kernel"
    echo -e "  ${PURPLE}Hardware Arch:${NC}    $hw_arch"
    
    # Show userspace architecture for Linux
    if [ "$os_kernel" = "Linux" ] && command -v getconf >/dev/null 2>&1; then
        userspace_bits=$(getconf LONG_BIT 2>/dev/null || echo "unknown")
        echo -e "  ${PURPLE}Userspace:${NC}        ${userspace_bits}-bit"
        
        # Detect mixed architecture scenarios
        if [ "$hw_arch" = "aarch64" ] && [ "$userspace_bits" = "32" ]; then
            echo -e "  ${YELLOW}⚠️  Mixed Architecture:${NC} 64-bit CPU with 32-bit userland detected"
            echo -e "     ${YELLOW}(Common on Raspberry Pi OS 32-bit)${NC}"
        fi
    fi
    
    echo "--------------------------------------------"
}

# Check if helm is installed
if ! command -v helm >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: helm is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install Helm first: https://helm.sh/docs/intro/install/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Helm found: $(helm version --short 2>/dev/null || helm version --client --short 2>/dev/null || echo 'Unknown version')${NC}"
echo ""

# Detect hardware details
detect_hardware_details
echo ""

# Check if plugin is already installed  
if helm plugin list 2>/dev/null | grep -q "^safe"; then
    echo -e "${YELLOW}⚠️  helm-safe plugin is already installed${NC}"
    
    # Non-interactive mode for CI/automated installs
    if [ -n "$HELM_SAFE_FORCE_REINSTALL" ] || [ "$1" = "--force" ]; then
        echo -e "${YELLOW}Force reinstall requested...${NC}"
        helm plugin uninstall helm-safe 2>/dev/null || true
    else
        # Interactive mode
        echo -e "${BLUE}Current installation:${NC}"
        helm plugin list | grep "^safe" || true
        echo ""
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Uninstalling existing plugin...${NC}"
            helm plugin uninstall helm-safe 2>/dev/null || true
        else
            echo -e "${GREEN}Installation cancelled. Plugin already exists.${NC}"
            echo -e "${BLUE}To force reinstall, use: HELM_SAFE_FORCE_REINSTALL=1 curl -sSL ... | bash${NC}"
            exit 0
        fi
    fi
fi

# Enhanced OS and architecture detection (integrated from go-extended script)
echo -e "${CYAN}🎯 Target Platform Detection${NC}"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_RAW=$(uname -m)
ARCH=""
GOARM=""

# Enhanced architecture detection with mixed-architecture support
case "$ARCH_RAW" in
    x86_64)
        ARCH="amd64"
        echo -e "  ${GREEN}✅ Architecture: x86_64 → amd64${NC}"
        ;;
    arm*|aarch64)
        # Advanced ARM detection using techniques from go-extended script
        if [ "$OS" = "linux" ] && command -v getconf >/dev/null 2>&1; then
            userspace_bits=$(getconf LONG_BIT 2>/dev/null || echo "64")
            
            if [ "$userspace_bits" = "32" ]; then
                # 32-bit userspace (even on 64-bit hardware)
                ARCH="arm"
                case "$ARCH_RAW" in
                    armv6l) GOARM="6" ;;
                    *) GOARM="7" ;;
                esac
                echo -e "  ${YELLOW}🔄 Architecture: $ARCH_RAW (32-bit userspace) → arm (GOARM=$GOARM)${NC}"
                
                # Special detection for mixed architecture systems
                if [ "$ARCH_RAW" = "aarch64" ]; then
                    echo -e "  ${PURPLE}🍓 Mixed Architecture: 64-bit CPU with 32-bit OS (Raspberry Pi style)${NC}"
                fi
            else
                # 64-bit userspace
                ARCH="arm64"
                echo -e "  ${GREEN}✅ Architecture: $ARCH_RAW (64-bit) → arm64${NC}"
            fi
        else
            # macOS or systems without getconf - use architecture directly
            case "$ARCH_RAW" in
                arm64|aarch64) 
                    ARCH="arm64"
                    echo -e "  ${GREEN}✅ Architecture: $ARCH_RAW → arm64${NC}"
                    ;;
                *)
                    # Fallback for 32-bit ARM
                    ARCH="arm"
                    GOARM="7"
                    echo -e "  ${YELLOW}🔄 Architecture: $ARCH_RAW → arm (GOARM=$GOARM)${NC}"
                    ;;
            esac
        fi
        ;;
    *)
        echo -e "${RED}❌ Unsupported architecture: $ARCH_RAW${NC}"
        echo -e "${YELLOW}Supported architectures:${NC}"
        echo -e "  • x86_64 (Intel/AMD 64-bit)"
        echo -e "  • arm64/aarch64 (64-bit ARM)"  
        echo -e "  • armv7l/armv6l (32-bit ARM)"
        echo -e "${BLUE}💡 For other architectures, Go source compilation may work${NC}"
        exit 1
        ;;
esac

# OS compatibility check
case $OS in
    linux)
        echo -e "  ${GREEN}✅ Operating System: Linux${NC}"
        ;;
    darwin)
        echo -e "  ${GREEN}✅ Operating System: macOS${NC}"
        ;;
    mingw*|msys*|cygwin*)
        OS="windows"
        echo -e "  ${GREEN}✅ Operating System: Windows${NC}"
        ;;
    *)
        echo -e "${RED}❌ Unsupported operating system: $OS${NC}"
        echo -e "${YELLOW}Supported systems: Linux, macOS, Windows${NC}"
        echo -e "${BLUE}💡 For other Unix systems, source compilation may work${NC}"
        exit 1
        ;;
esac

# Show final platform detection
echo ""
echo -e "${GREEN}🎯 Target Platform: ${OS}-${ARCH}${NC}"
if [ -n "$GOARM" ]; then
    echo -e "${PURPLE}🔧 ARM Version: GOARM=${GOARM}${NC}"
fi

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
if helm plugin list | grep -q "^safe"; then
    PLUGIN_VERSION=$(helm plugin list | grep "^safe" | awk '{print $2}')
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