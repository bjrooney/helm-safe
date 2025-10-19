#!/bin/bash

echo "Testing helm-safe binary..."

# Test if binary exists and is executable
if [ -f "./bin/helm-safe" ]; then
    echo "✓ Binary exists"
    if [ -x "./bin/helm-safe" ]; then
        echo "✓ Binary is executable"
    else
        echo "✗ Binary is not executable"
        chmod +x ./bin/helm-safe
        echo "  Fixed permissions"
    fi
else
    echo "✗ Binary not found"
    exit 1
fi

# Test help command
echo ""
echo "Testing --help:"
./bin/helm-safe --help

echo ""
echo "Testing version:"
./bin/helm-safe --version

echo ""
echo "Testing with no args:"
./bin/helm-safe

echo ""
echo "Testing safe command (list):"
./bin/helm-safe list

echo ""
echo "Testing modifying command without required flags:"
./bin/helm-safe install test-release

echo ""
echo "Done!"