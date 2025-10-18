#!/bin/bash

# Test script to verify the installation issue is fixed

echo "Testing helm-safe installation fix..."

# Simulate the failed installation scenario
export HELM_PLUGIN_DIR="/tmp/test-helm-safe"
mkdir -p "$HELM_PLUGIN_DIR"

# Copy our current repository to the test directory
cp -r . "$HELM_PLUGIN_DIR/"

echo "Running install-simple.sh in test environment..."
cd "$HELM_PLUGIN_DIR"

# Run the installation script
bash scripts/install-simple.sh

if [ $? -eq 0 ]; then
    echo "✅ Installation script completed successfully!"
    if [ -f "bin/helm-safe" ]; then
        echo "✅ Binary exists at bin/helm-safe"
        if [ -x "bin/helm-safe" ]; then
            echo "✅ Binary is executable"
            echo "🎉 Installation fix verified!"
        else
            echo "❌ Binary is not executable"
        fi
    else
        echo "❌ Binary not found at bin/helm-safe"
    fi
else
    echo "❌ Installation script failed"
fi

# Clean up
rm -rf "$HELM_PLUGIN_DIR"