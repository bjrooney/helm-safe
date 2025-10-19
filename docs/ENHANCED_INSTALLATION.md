# 🚀 Enhanced Installation System

The helm-safe plugin now features a comprehensive, intelligent installation system that replaces the previous separate quick-install.sh script.

## 🎯 Key Features

### 🔍 Advanced Hardware Detection
- **Raspberry Pi Support**: Detects mixed architectures (64-bit CPU + 32-bit OS)
- **Apple Silicon**: Native ARM64 detection for M1/M2/M3 Macs
- **x86_64 Systems**: Standard Intel/AMD 64-bit support
- **ARM Variants**: Supports ARMv6, ARMv7, and ARM64 architectures
- **Hardware Identification**: Shows manufacturer, model, and system details

### 📊 Intelligent Platform Selection
- **Mixed Architecture**: Handles Raspberry Pi OS 32-bit on 64-bit hardware
- **Userspace Detection**: Uses `getconf LONG_BIT` for accurate bit depth
- **GOARM Support**: Automatically sets ARM version flags (6 or 7)
- **Fallback Logic**: Graceful degradation for unknown systems

### 🛠️ Comprehensive Installation Methods
- **Pre-built Binaries**: Downloads optimized binaries when available
- **Source Compilation**: Automatic fallback with Go detection
- **Dependency Management**: Handles missing Go installation
- **Verification**: Tests installation and functionality

## 📋 Installation Output Example

```
========================================
    🛡️  Helm Safe Plugin Installer
========================================

✅ Helm found: v3.19.0+g3d8990f

🔍 Hardware Detection
--------------------------------------------
  Supplier:         Raspberry Pi Foundation
  Model:            Raspberry Pi 4 Model B Rev 1.4
  OS Kernel:        Linux
  Hardware Arch:    aarch64
  Userspace:        32-bit
  ⚠️  Mixed Architecture: 64-bit CPU with 32-bit userland detected
     (Common on Raspberry Pi OS 32-bit)
--------------------------------------------

🎯 Target Platform Detection
  🔄 Architecture: aarch64 (32-bit userspace) → arm (GOARM=7)
  🍓 Mixed Architecture: 64-bit CPU with 32-bit OS (Raspberry Pi style)
  ✅ Operating System: Linux

🎯 Target Platform: linux-arm
🔧 ARM Version: GOARM=7

Installing helm-safe plugin...
🎉 helm-safe plugin installed successfully!
```

## 🔧 Technical Details

### Architecture Mapping
| Hardware | OS Type | Detection Result | Binary Used |
|----------|---------|------------------|-------------|
| x86_64 | Any | `amd64` | Standard 64-bit |
| aarch64 | 64-bit userspace | `arm64` | Native ARM64 |
| aarch64 | 32-bit userspace | `arm` (GOARM=7) | 32-bit ARM |
| armv7l | Any | `arm` (GOARM=7) | 32-bit ARM |
| armv6l | Any | `arm` (GOARM=6) | 32-bit ARM |

### Installation Priority
1. **Helm Plugin Install** - Uses Helm's native plugin system
2. **Binary Download** - Pre-built binaries from GitHub releases  
3. **Source Compilation** - Builds from source with Go
4. **Error Guidance** - Detailed troubleshooting information

## 🎛️ Usage Options

### Standard Installation
```bash
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash
```

### Force Reinstall (Non-interactive)
```bash
HELM_SAFE_FORCE_REINSTALL=1 curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash
```

### Direct Helm Plugin Install
```bash
helm plugin install https://github.com/bjrooney/helm-safe
```

### Command Line Force Flag
```bash
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash -s -- --force
```

## 🛡️ Benefits Over Previous System

### Before (Multiple Scripts)
- `quick-install.sh` - Basic installation
- `raspberry-pi-install-fix.sh` - Raspberry Pi specific
- `install.sh` - Plugin hook script
- Limited hardware detection
- Separate troubleshooting scripts

### After (Unified System)
- **Single Entry Point** - One script handles all scenarios
- **Advanced Detection** - Comprehensive hardware analysis
- **Better UX** - Rich output with emojis and colors
- **Robust Fallbacks** - Multiple installation strategies
- **Self-Diagnosing** - Built-in troubleshooting guidance

## 🔍 Troubleshooting Integration

The installer includes built-in diagnostics that help identify issues:

- **Hardware Compatibility** - Shows exact system configuration
- **Architecture Mismatches** - Detects and explains mixed architectures  
- **Dependency Issues** - Checks for required tools (Go, Helm)
- **Network Problems** - Provides alternative installation methods
- **Permission Issues** - Suggests solutions for access problems

This unified approach significantly improves the installation experience while maintaining backward compatibility and adding support for edge cases like Raspberry Pi mixed architectures.