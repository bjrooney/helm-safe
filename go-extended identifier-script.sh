#!/bin/bash

# identify_go_build_env.sh (Hardware-Aware)
# This script identifies the OS, hardware architecture, and system model/supplier.
# It then provides the correct Go environment variables for the host machine.

# --- Initial Setup ---
OS_KERNEL=$(uname -s)
HW_ARCH=$(uname -m)

# Variables for Go environment
GOOS_VAL=""
GOARCH_VAL=""
GOARM_VAL=""

# Variables for Hardware ID
HW_SUPPLIER="Unknown"
HW_MODEL="Unknown"


# --- Step 1: Determine the Go Operating System (GOOS) ---
case "$OS_KERNEL" in
    Linux)
        if command -v getprop > /dev/null 2>&1; then
            GOOS_VAL="android"
        else
            GOOS_VAL="linux"
        fi
        ;;
    Darwin)
        GOOS_VAL="darwin"
        ;;
    *)
        echo "Unsupported Operating System: $OS_KERNEL"
        exit 1
        ;;
esac


# --- Step 2: Identify Hardware Supplier and Model ---
case "$OS_KERNEL" in
    Darwin)
        HW_SUPPLIER="Apple"
        # Get the human-readable model name like "MacBook Pro"
        MODEL_NAME=$(system_profiler SPHardwareDataType | awk -F: '/Model Name/ {print $2}' | sed 's/^ *//')
        # Get the specific model identifier like "MacBookPro18,1"
        MODEL_ID=$(sysctl -n hw.model)
        HW_MODEL="$MODEL_NAME ($MODEL_ID)"
        ;;
    Linux)
        # Most specific check first: Raspberry Pi Device Tree
        if [ -f /sys/firmware/devicetree/base/model ]; then
            HW_SUPPLIER="Raspberry Pi Foundation"
            # Read the model and remove any trailing null characters
            HW_MODEL=$(tr -d '\0' < /sys/firmware/devicetree/base/model)
        # Next, check for Android properties
        elif [ "$GOOS_VAL" = "android" ]; then
            HW_SUPPLIER=$(getprop ro.product.manufacturer)
            HW_MODEL=$(getprop ro.product.model)
        # Next, check standard DMI/SMBIOS for PCs/servers
        elif [ -d /sys/class/dmi/id/ ]; then
            if [ -f /sys/class/dmi/id/sys_vendor ]; then
                HW_SUPPLIER=$(cat /sys/class/dmi/id/sys_vendor)
            fi
            if [ -f /sys/class/dmi/id/product_name ]; then
                HW_MODEL=$(cat /sys/class/dmi/id/product_name)
            fi
        # Fallback to CPU info if all else fails
        else
            if [ -f /proc/cpuinfo ]; then
                HW_SUPPLIER=$(grep -m 1 'vendor_id' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^ *//')
                HW_MODEL=$(grep -m 1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | sed 's/^ *//')
            fi
        fi
        ;;
esac


# --- Step 3: Determine the Go Architecture (GOARCH) ---
case "$HW_ARCH" in
    x86_64)
        GOARCH_VAL="amd64"
        ;;
    arm* | aarch64)
        if [ "$OS_KERNEL" = "Linux" ] && [ -x /usr/bin/getconf ]; then
            if [ "$(getconf LONG_BIT)" = "32" ]; then
                GOARCH_VAL="arm"
                case "$HW_ARCH" in
                    armv6l) GOARM_VAL="6" ;;
                    *) GOARM_VAL="7" ;;
                esac
            else
                GOARCH_VAL="arm64"
            fi
        else # For macOS or systems without getconf
            case "$HW_ARCH" in
                arm64 | aarch64) GOARCH_VAL="arm64" ;;
                *) # Fallback for 32-bit
                   GOARCH_VAL="arm"
                   GOARM_VAL="7" ;;
            esac
        fi
        ;;
    *)
        echo "Unsupported Hardware Architecture: $HW_ARCH"
        exit 1
        ;;
esac


# --- Step 4: Display the Results ---
echo "----------------------------------------------------"
echo "Host System Information Detected:"
echo "  Supplier:         $HW_SUPPLIER"
echo "  Model:            $HW_MODEL"
echo ""
echo "  Operating System: $OS_KERNEL (GOOS=$GOOS_VAL)"
echo "  Hardware Arch:    $HW_ARCH"
if [ "$OS_KERNEL" = "Linux" ]; then
    # Only try to run getconf if it exists
    if command -v getconf > /dev/null 2>&1; then
        echo "  Userspace Arch:   $(getconf LONG_BIT)-bit"
    fi
fi
echo "  => Go Target Arch: (GOARCH=$GOARCH_VAL)"
if [ -n "$GOARM_VAL" ]; then
    echo "  => Go ARM Version: (GOARM=$GOARM_VAL)"
fi
echo "----------------------------------------------------"
echo ""
echo "== To compile a Go program FOR THIS machine, use: =="

if [ -n "$GOARM_VAL" ]; then
    echo "GOOS=$GOOS_VAL GOARCH=$GOARCH_VAL GOARM=$GOARM_VAL go build main.go"
else
    echo "GOOS=$GOOS_VAL GOARCH=$GOARCH_VAL go build main.go"
fi
echo ""
echo "----------------------------------------------------"
```eof

### How to Use

1.  **Save the file:** Save the code above into a file named `identify_go_build_env.sh`.
2.  **Make it executable:** Open your terminal and run the command: `chmod +x identify_go_build_env.sh`
3.  **Run it:** Execute the script from your terminal: `./identify_go_build_env.sh`