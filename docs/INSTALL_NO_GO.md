# Quick Installation Guide for Systems Without Go

If you're installing helm-safe on a system without Go (like the error you encountered), here are your options:

## ✅ Option 1: Use Pre-built Binaries (Recommended)

### For Linux ARM64 (your case):
```bash
# Uninstall the failed installation first
helm plugin uninstall safe

# Download the pre-built binary directly
curl -L https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-linux-arm64 -o /tmp/helm-safe
chmod +x /tmp/helm-safe

# Create a simple plugin directory
mkdir -p ~/.local/share/helm/plugins/helm-safe/bin
cp /tmp/helm-safe ~/.local/share/helm/plugins/helm-safe/bin/helm-safe

# Create a simple plugin.yaml
cat > ~/.local/share/helm/plugins/helm-safe/plugin.yaml << 'EOF'
name: safe
version: 0.1.0
usage: Interactive safety net for modifying Helm commands
description: Interactive safety net for modifying Helm commands
command: ${HELM_PLUGIN_DIR}/bin/helm-safe
EOF

# Test it
helm safe --help
```

## ✅ Option 2: Manual Installation Steps

1. **Download the correct binary for your platform:**
   - Linux AMD64: `helm-safe-linux-amd64`
   - Linux ARM64: `helm-safe-linux-arm64` 
   - macOS AMD64: `helm-safe-darwin-amd64`
   - macOS ARM64: `helm-safe-darwin-arm64`
   - Windows: `helm-safe-windows-amd64.exe`

2. **Get from GitHub releases:**
   ```bash
   curl -L https://github.com/bjrooney/helm-safe/releases/latest/download/helm-safe-linux-arm64 -o helm-safe
   chmod +x helm-safe
   ```

3. **Copy to Helm plugins directory:**
   ```bash
   mkdir -p $(helm env HELM_PLUGINS)/safe/bin
   cp helm-safe $(helm env HELM_PLUGINS)/safe/bin/
   ```

4. **Create plugin manifest:**
   ```bash
   cat > $(helm env HELM_PLUGINS)/safe/plugin.yaml << 'EOF'
   name: safe
   version: 0.1.0
   usage: Interactive safety net for modifying Helm commands
   description: Interactive safety net for modifying Helm commands
   command: ${HELM_PLUGIN_DIR}/bin/helm-safe
   EOF
   ```

## ✅ Option 3: Install Go and Build from Source

```bash
# Install Go (if you have admin access)
# On Ubuntu/Debian:
sudo apt update && sudo apt install golang-go

# On CentOS/RHEL:
sudo yum install golang

# Then try the plugin install again:
helm plugin install https://github.com/bjrooney/helm-safe
```

## 🧪 Test Installation

After any of the above methods:
```bash
helm safe --help
helm safe list  # Should pass through to regular helm list
helm safe install test --help  # Should show safety warnings
```

## 🚨 Common Issues

- **Permission denied**: Make sure the binary is executable (`chmod +x`)
- **Command not found**: Check that the plugin directory is correct
- **Plugin already exists**: Run `helm plugin uninstall safe` first

The key insight is that the plugin tried to build from source but Go wasn't available. The pre-built binaries solve this problem completely.