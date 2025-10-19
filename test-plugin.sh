#!/bin/bash

echo "=== Testing helm-safe plugin ==="
echo

echo "1. Testing version:"
helm safe --version
echo

echo "2. Testing help:"
helm safe --help | head -10
echo

echo "3. Testing status without release name (should show Helm error):"
helm safe status
echo

echo "4. Testing list (safe command, should pass through):"
helm safe list
echo

echo "5. Testing plugin verification:"
helm plugin list | grep safe