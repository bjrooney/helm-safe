# 🍓 Raspberry Pi Installation Guide

This guide provides specific instructions for installing helm-safe on Raspberry Pi systems, which often have mixed architecture configurations.

## 🔍 Common Raspberry Pi Issues

Raspberry Pi systems often run 32-bit operating systems on 64-bit hardware, which can cause binary compatibility issues:

- **Hardware**: 64-bit ARM CPU (aarch64)
- **OS**: 32-bit Raspberry Pi OS (armhf/armv7l userland)
- **Result**: Standard arm64 binaries won't work

## 🚀 Quick Fix Installation

If you're experiencing installation issues, use our specialized fix script:

```bash
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/raspberry-pi-install-fix.sh | bash
```

This script will:
- ✅ Clean up any corrupted installations
- ✅ Detect your exact architecture configuration
- ✅ Download the correct binary for your system
- ✅ Fall back to source compilation if needed
- ✅ Verify the installation works

## 🔧 Manual Installation Steps

If the automated script doesn't work:

### Step 1: Clean Up Corrupted Installation

```bash
# Remove any existing broken installation
helm plugin uninstall safe 2>/dev/null || true

# Manual cleanup if needed
rm -rf ~/.local/share/helm/plugins/helm-safe
rm -rf ~/.helm/plugins/helm-safe
```

### Step 2: Install from Source (Recommended for Raspberry Pi)

```bash
# Install Go if not available
sudo apt update && sudo apt install golang-go

# Clone and install
git clone https://github.com/bjrooney/helm-safe /tmp/helm-safe
cd /tmp/helm-safe
helm plugin install .
```

### Step 3: Verify Installation

```bash
helm plugin list | grep safe
helm safe --version
helm safe --help
```

## 🏗️ Architecture Detection

Our installer automatically detects these Raspberry Pi configurations:

| Hardware | OS | Detection | Binary Used |
|----------|----|-----------| ------------|
| aarch64 | Raspberry Pi OS 32-bit | 32-bit userland detected | `linux-arm` |
| aarch64 | Ubuntu 64-bit | Native 64-bit | `linux-arm64` |
| armv7l | Raspberry Pi OS 32-bit | Native 32-bit | `linux-arm` |
| armv6l | Older Pi models | Native 32-bit | `linux-arm` |

## 🧪 Troubleshooting

### Issue: "exec format error"
**Cause**: Wrong binary architecture for your system  
**Solution**: Use the fix script or install from source

### Issue: "Binary appears corrupted"
**Cause**: Incomplete download or network issues  
**Solution**: The fix script tries multiple download methods

### Issue: "Plugin already exists" but doesn't work
**Cause**: Corrupted installation state  
**Solution**: Use the cleanup steps in the fix script

### Issue: "Go not found"
**Solution**: Install Go first:
```bash
# Raspberry Pi OS / Debian / Ubuntu
sudo apt update && sudo apt install golang-go

# Or download from https://golang.org/dl/
```

## 📊 System Information

To help with troubleshooting, you can gather system info:

```bash
# Check your system details
uname -a
cat /proc/cpuinfo | grep -E "(Hardware|Revision|Model)"
ls -la /lib/arm-linux-gnueabihf 2>/dev/null || echo "No armhf libs"

# Check available binaries
curl -s https://api.github.com/repos/bjrooney/helm-safe/releases/latest | \
  jq -r '.assets[].name' | grep linux-arm
```

## 🆘 Getting Help

If you're still having issues:

1. **Run the diagnostic script**:
   ```bash
   curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/raspberry-pi-diagnostic.sh | bash
   ```

2. **Create an issue** with the diagnostic output:
   - Go to: https://github.com/bjrooney/helm-safe/issues
   - Include your system information and error messages
   - Tag with `raspberry-pi` label

3. **Try the community**:
   - Check existing issues for similar problems
   - Look for Raspberry Pi specific solutions

## ✅ Success Indicators

After successful installation, you should see:

```bash
❯ helm plugin list
NAME    VERSION DESCRIPTION
safe    v0.1.9  A safety net for Helm operations

❯ helm safe --version
helm-safe version v0.1.9

❯ helm safe status
Current Helm context: your-context
Current namespace: default
```

---

**💡 Pro Tip**: The source installation method is often the most reliable for Raspberry Pi systems, as it compiles the binary specifically for your exact system configuration.