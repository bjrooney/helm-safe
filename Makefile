.PHONY: build test clean install version dev-install cross-build

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

# Increment patch version
bump-patch:
	@current=$$(cat $(VERSION_FILE) 2>/dev/null || echo "0.0.0"); \
	major=$$(echo $$current | cut -d. -f1); \
	minor=$$(echo $$current | cut -d. -f2); \
	patch=$$(echo $$current | cut -d. -f3); \
	new_patch=$$((patch + 1)); \
	new_version="$$major.$$minor.$$new_patch"; \
	echo "$$new_version" > $(VERSION_FILE); \
	echo "Version bumped from $$current to $$new_version"

test:
	@echo "Running tests..."
	go test -v ./pkg/...

clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR)

# Cross-platform build for all supported platforms
cross-build:
	@echo "Building for all platforms..."
	@mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 ./cmd/helm-safe
	GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 ./cmd/helm-safe
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 ./cmd/helm-safe
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 ./cmd/helm-safe
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe ./cmd/helm-safe
	@echo "Cross-compilation complete!"

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