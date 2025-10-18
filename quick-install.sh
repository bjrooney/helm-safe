#!/bin/bash

# Simple helm-safe installation script
# Usage: curl -sSL https://raw.githubusercontent.com/bjrooney/helm-safe/main/quick-install.sh | bash

set -e

PLUGIN_URL="https://github.com/bjrooney/helm-safe"

echo "Installing helm-safe plugin..."

# Check if helm is available
if ! command -v helm >/dev/null 2>&1; then
    echo "Error: helm command not found. Please install Helm first."
    exit 1
fi

# Install the plugin
helm plugin install "$PLUGIN_URL"

echo "helm-safe plugin installed successfully!"
echo ""
echo "Quick start:"
echo "  helm safe status              # Check current context"
echo "  helm safe install app ./chart # Safe install with confirmation"  
echo "  helm safe --help              # Show all commands"