# Helm-Safe Installation Guide

## Quick Start

### 1. Build the Plugin
```bash
cd /Users/brendanrooney/Documents/projects/brendan/helm-safe
make build
```

### 2. Test the Binary
```bash
./bin/helm-safe --help
./bin/helm-safe --version
```

### 3. Manual Plugin Installation

Since Helm might not be installed or configured, here's how to install manually:

#### Option A: Install Helm first, then install plugin
```bash
# Install Helm (macOS)
brew install helm

# Verify installation
helm version

# Install our plugin
helm plugin install /Users/brendanrooney/Documents/projects/brendan/helm-safe

# Test the plugin
helm safe --help
```

#### Option B: Use the binary directly
```bash
# Copy binary to your PATH
sudo cp /Users/brendanrooney/Documents/projects/brendan/helm-safe/bin/helm-safe /usr/local/bin/

# Test it
helm-safe --help
```

#### Option C: Create an alias
```bash
# Add to your ~/.zshrc
echo 'alias helm-safe="/Users/brendanrooney/Documents/projects/brendan/helm-safe/bin/helm-safe"' >> ~/.zshrc
source ~/.zshrc

# Test it
helm-safe --help
```

### 4. Testing the Plugin

```bash
# Safe commands (should pass through)
helm safe list
helm safe status my-release
helm safe get values my-release

# Modifying commands (should require flags)
helm safe install my-app ./chart
# ^ This should show an error about missing --namespace and --kube-context

# Proper usage
helm safe install my-app ./chart --namespace default --kube-context minikube
```

## Troubleshooting

### If you see "unknown command safe"
- Helm is not installed or plugin not installed
- Use `helm plugin list` to see installed plugins
- Use `helm env` to see where plugins should be installed

### If you see permission errors
```bash
chmod +x /Users/brendanrooney/Documents/projects/brendan/helm-safe/bin/helm-safe
```

### If dependencies are missing
```bash
cd /Users/brendanrooney/Documents/projects/brendan/helm-safe
go mod tidy
make build
```

## Creating a GitHub Repository

Once everything works, create a GitHub repo:

```bash
cd /Users/brendanrooney/Documents/projects/brendan/helm-safe
git init
git add .
git commit -m "Initial commit: helm-safe plugin"

# Create repo on GitHub
gh repo create helm-safe --public
git remote add origin https://github.com/bjrooney/helm-safe.git
git push -u origin main
```

Then users can install with:
```bash
helm plugin install https://github.com/bjrooney/helm-safe
```