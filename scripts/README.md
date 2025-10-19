# 🔧 Scripts Directory

This directory contains development, build, and maintenance scripts for the helm-safe project.

## 📁 Script Categories

### 🚀 Installation Scripts (Development/Alternative Methods)
- **`install.sh`** - Main plugin installer (also used by plugin.yaml)
- **`install-simple.sh`** - Simple installation without advanced detection
- **`install-smart.sh`** - Smart installation with architecture detection
- **`install-build-first.sh`** - Build-first installation approach
- **`install-with-targz.sh`** - Installation using tar.gz downloads

### 🏗️ Build & Release Scripts
- **`create-release.sh`** - Automated release creation and tagging
- **`manual-release.sh`** - Manual release process for troubleshooting
- **`go-app-installer-windows.sh`** - Windows-specific Go app installer
- **`go-extended identifier-script.sh`** - Extended Go build identifier script

### 🧪 Testing & Development Scripts  
- **`test-install.sh`** - Test installation process
- **`test-plugin.sh`** - Test plugin functionality
- **`demo.sh`** - Demo script for showcasing features
- **`debug-platform.sh`** - Platform detection debugging

### 🛡️ Repository Management Scripts
- **`setup-branch-protection.sh`** - GitHub branch protection setup (with status checks)
- **`setup-branch-protection-simple.sh`** - Basic branch protection setup (no status checks)

## 🌐 Remote Installation Scripts (Root Level)

These scripts remain in the project root for direct remote access via curl/wget:

- **`quick-install.sh`** - Main entry point for users
- **`raspberry-pi-install-fix.sh`** - Raspberry Pi installation fix
- **`raspberry-pi-diagnostic.sh`** - User troubleshooting tool
- **`install.sh`** - Core plugin installer (referenced by plugin.yaml)

## 📋 Usage Examples

### Development & Testing
```bash
# Test installation locally
./scripts/test-install.sh

# Test plugin functionality  
./scripts/test-plugin.sh

# Debug platform detection
./scripts/debug-platform.sh

# Run demo
./scripts/demo.sh
```

### Release Management
```bash
# Create new release
./scripts/create-release.sh

# Manual release process
./scripts/manual-release.sh
```

### Repository Setup
```bash
# Set up branch protection
./scripts/setup-branch-protection-simple.sh

# Set up advanced branch protection with CI
./scripts/setup-branch-protection.sh
```

### Installation Development
```bash
# Test different installation methods
./scripts/install-simple.sh
./scripts/install-smart.sh
./scripts/install-build-first.sh
```

## 🔧 Script Dependencies

### Required Tools
- **bash** - All scripts require bash shell
- **git** - Required for release and repository management scripts
- **go** - Required for build scripts and some installation methods
- **helm** - Required for plugin testing scripts
- **curl/wget** - Required for download-based installation scripts

### GitHub CLI (Optional)
- **gh** - Required for branch protection scripts and some release automation

## 📚 Related Documentation

- **[Installation Guide](../docs/INSTALLATION.md)** - User installation instructions
- **[Branch Protection Setup](../docs/BRANCH_PROTECTION_SETUP.md)** - Repository protection guide
- **[Raspberry Pi Install](../docs/RASPBERRY_PI_INSTALL.md)** - Platform-specific installation

## 🛠️ Development Workflow

1. **Local Development**: Use test scripts to verify changes
2. **Platform Testing**: Use debug and installation scripts for cross-platform testing  
3. **Release Preparation**: Use release scripts for version management
4. **Repository Management**: Use setup scripts for GitHub configuration

## 📝 Adding New Scripts

When adding new scripts to this directory:

1. **Make executable**: `chmod +x script-name.sh`
2. **Add to appropriate category** in this README
3. **Include usage example** if complex
4. **Document dependencies** if any special requirements
5. **Consider if it should be in root** for remote access

---

💡 **Note**: Scripts in this directory are for development and maintenance. End users should use the root-level installation scripts via remote download.