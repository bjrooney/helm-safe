# Installation Scripts

This directory contains installation scripts to make installing the helm-safe plugin as easy as possible.

## Quick Installation

For most users, the quickest way to install helm-safe is:

```bash
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash
```

## Available Scripts

### 1. `install.sh` - Full Installation Script

**Usage:**
```bash
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh | bash
```

**Features:**
- ✅ Comprehensive error checking and validation
- ✅ Detects if Helm is installed
- ✅ Checks for existing plugin installation
- ✅ Prompts for confirmation before reinstalling
- ✅ Platform detection (Linux, macOS, Windows)
- ✅ Architecture detection (amd64, arm64)
- ✅ Plugin verification after installation
- ✅ Colored output and clear feedback
- ✅ Troubleshooting instructions on failure

### 2. `quick-install.sh` - Simple Installation Script

**Usage:**
```bash
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/quick-install.sh | bash
```

**Features:**
- ✅ Minimal and fast
- ✅ Basic error checking
- ✅ Quick start instructions
- ✅ Perfect for automated setups

## Alternative Installation Methods

If the scripts don't work for your environment, you can also install manually:

### Direct Helm Plugin Install
```bash
helm plugin install https://github.com/bjrooney/helm-safe
```

### Manual Download and Install
```bash
git clone https://github.com/bjrooney/helm-safe.git
cd helm-safe
helm plugin install .
```

## Troubleshooting

### Script Doesn't Run
```bash
# Download and inspect first
curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh > install.sh
cat install.sh  # Review the script
bash install.sh
```

### Behind Corporate Firewall
```bash
# Download manually and run locally
wget https://raw.githubusercontent.com/bjrooney/helm-safe/main/install.sh
bash install.sh
```

### No Internet Access
1. Download the entire repository as a ZIP file
2. Extract and run: `helm plugin install ./helm-safe`

## Script Safety

Both installation scripts:
- ✅ Use `set -e` for immediate exit on errors
- ✅ Don't require sudo/root privileges
- ✅ Only install to standard Helm plugin directories
- ✅ Are open source and can be audited
- ✅ Use official Helm plugin installation mechanisms

## What the Scripts Do

1. **Check Prerequisites**: Verify Helm is installed and accessible
2. **Detect Platform**: Identify your operating system and architecture
3. **Check Existing Installation**: Avoid conflicts with existing plugins
4. **Install Plugin**: Use `helm plugin install` with the GitHub URL
5. **Verify Installation**: Confirm the plugin was installed correctly
6. **Provide Usage Instructions**: Show you how to get started

## After Installation

Once installed, you can start using helm-safe immediately:

```bash
# Check plugin is working
helm safe --help

# Replace dangerous commands with safe versions
helm safe install myapp ./chart --namespace myapp --kube-context dev-cluster

# Safe commands pass through without confirmation
helm safe list --all-namespaces
```

---

**Need help?** Open an issue at: https://github.com/bjrooney/helm-safe/issues