.PHONY: build test clean install version dev-install cross-build sync-version check-version bump-patch

BINARY_NAME=helm-safe
BUILD_DIR=bin
VERSION_FILE=VERSION

# Read version from VERSION file, or use "dev" if file doesn't exist
VERSION := $(shell cat $(VERSION_FILE) 2>/dev/null || echo "dev")
LDFLAGS := -ldflags "-X github.com/bjrooney/helm-safe/pkg/safe.Version=$(VERSION)"

build:
	@echo "Building $(BINARY_NAME) version $(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/helm-safe

version:
	@echo "Current version: $(VERSION)"

# Sync plugin.yaml version with VERSION file
sync-version:
	@echo "Syncing plugin.yaml version with VERSION file..."
	@VERSION_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "dev"); \
	sed -i.bak "s/^version: .*/version: $$VERSION_NUM/" plugin.yaml; \
	rm -f plugin.yaml.bak; \
	echo "Updated plugin.yaml to version: $$VERSION_NUM"

# Verify versions are in sync
check-version:
	@VERSION_FILE_NUM=$$(cat $(VERSION_FILE) 2>/dev/null || echo "unknown"); \
	PLUGIN_VERSION=$$(grep "^version:" plugin.yaml | awk '{print $$2}' | tr -d '"' || echo "unknown"); \
	if [ "$$VERSION_FILE_NUM" != "$$PLUGIN_VERSION" ]; then \
		echo "❌ Version mismatch:"; \
		echo "  VERSION file: $$VERSION_FILE_NUM"; \
		echo "  plugin.yaml:  $$PLUGIN_VERSION"; \
		echo "Run 'make sync-version' to fix this."; \
		exit 1; \
	else \
		echo "✅ Versions are in sync: $$VERSION_FILE_NUM"; \
	fi

# Increment patch version and sync
bump-patch:
	@current=$$(cat $(VERSION_FILE) 2>/dev/null || echo "0.0.0"); \
	major=$$(echo $$current | cut -d. -f1); \
	minor=$$(echo $$current | cut -d. -f2); \
	patch=$$(echo $$current | cut -d. -f3); \
	new_patch=$$((patch + 1)); \
	new_version="$$major.$$minor.$$new_patch"; \
	echo "$$new_version" > $(VERSION_FILE); \
	echo "Version bumped from $$current to $$new_version"; \
	$(MAKE) sync-version

test:
	@echo "Running tests..."
	go test -v ./pkg/...

clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR)

# Cross-platform build for all supported platforms
cross-build: check-version
	@echo "Building for all platforms..."
	@echo "Go version: $(shell go version)"
	@echo "Build environment: GOOS=$(shell go env GOOS) GOARCH=$(shell go env GOARCH)"
	@mkdir -p $(BUILD_DIR)
	@echo "Building linux-amd64..."
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 ./cmd/helm-safe
	@echo "Building linux-arm64..."
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 ./cmd/helm-safe
	@echo "Building linux-arm (GOARM=7)..."
	GOOS=linux GOARCH=arm GOARM=7 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm ./cmd/helm-safe
	@echo "Building linux-arm (GOARM=6)..."
	GOOS=linux GOARCH=arm GOARM=6 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-armv6 ./cmd/helm-safe
	@echo "Building darwin-amd64..."
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 ./cmd/helm-safe
	@echo "Building darwin-arm64..."
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 ./cmd/helm-safe
	@echo "Building windows-amd64..."
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe ./cmd/helm-safe
	@echo "Cross-compilation complete!"
	@echo "Built binaries:"
	@ls -la $(BUILD_DIR)/

# Install plugin locally for development
dev-install: build
	@echo "Installing $(BINARY_NAME) for local development..."
	@if ! command -v helm >/dev/null 2>&1; then \
		echo "Error: helm command not found. Please install Helm first."; \
		exit 1; \
	fi
	@HELM_PLUGINS=$$(helm env HELM_PLUGINS); \
	PLUGIN_DIR="$$HELM_PLUGINS/safe"; \
	echo "Installing to: $$PLUGIN_DIR"; \
	mkdir -p "$$PLUGIN_DIR"; \
	cp -r . "$$PLUGIN_DIR/"; \
	echo "Plugin installed! Usage: helm safe [command]"

# Uninstall the plugin
dev-uninstall:
	@echo "Uninstalling helm-safe plugin..."
	@HELM_PLUGINS=$$(helm env HELM_PLUGINS); \
	PLUGIN_DIR="$$HELM_PLUGINS/safe"; \
	if [ -d "$$PLUGIN_DIR" ]; then \
		rm -rf "$$PLUGIN_DIR"; \
		echo "Plugin uninstalled successfully"; \
	else \
		echo "Plugin not found at $$PLUGIN_DIR"; \
	fi

# Initialize go modules
init:
	go mod init github.com/bjrooney/helm-safe
	go mod tidy

# Format code
fmt:
	go fmt ./...

# Lint code (requires golangci-lint)
lint:
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not found, skipping linting"; \
	fi

# Show available targets
help:
	@echo "Available targets:"
	@echo "  build          - Build binary for current platform"
	@echo "  cross-build    - Build for all supported platforms"
	@echo "  test           - Run tests"
	@echo "  clean          - Clean build artifacts"
	@echo ""
	@echo "Version management:"
	@echo "  version        - Show current version"
	@echo "  check-version  - Verify VERSION and plugin.yaml are in sync"
	@echo "  sync-version   - Sync plugin.yaml version with VERSION file"
	@echo "  bump-patch     - Increment patch version and sync"
	@echo ""
	@echo "Development:"
	@echo "  dev-install    - Install plugin locally for development"
	@echo "  fmt            - Format code"
	@echo "  lint           - Lint code (requires golangci-lint)"