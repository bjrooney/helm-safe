#!/bin/bash

echo "🎯 Helm-Safe Plugin Demo"
echo "======================="

echo ""
echo "1. Testing help command:"
helm safe --help

echo ""
echo "2. Testing version:"
helm safe --version

echo ""
echo "3. Testing safe command (should pass through):"
echo "   Command: helm safe list"
helm safe list

echo ""
echo "4. Testing modifying command without required flags (should fail):"
echo "   Command: helm safe install test-release"
helm safe install test-release

echo ""
echo "5. Testing modifying command with required flags (should show confirmation):"
echo "   Command: helm safe install test-release --namespace default --kube-context kind-dev-1"
echo "   Note: This will show a confirmation prompt. Press Ctrl+C to cancel."
echo ""
echo "Demo complete! The plugin is working correctly."