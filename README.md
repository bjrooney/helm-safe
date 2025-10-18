# helm-safe

A Helm plugin that provides an interactive safety net for modifying Helm commands.

## Overview

helm-safe acts as a simple, interactive wrapper around modifying Helm commands to prevent common, high-impact mistakes. It's designed to be a final checkpoint before you make a change you might regret.

## Features

- **Enforces Best Practices**: Requires the mandatory use of `--namespace` and `--kube-context` flags, forcing you to be explicit about your target
- **Context Validation**: Validates that the specified context exists in your kubeconfig to prevent typos and targeting non-existent clusters
- **Interactive Confirmation**: Shows detailed information about the target cluster and namespace before executing modifying commands
- **Production Alerts**: Special warnings for production-like contexts (contexts containing "prod", "production", "live", etc.)
- **Transparent Pass-through**: Safe commands like `list`, `status`, `get`, `history` etc. are passed through without any checks
- **Comprehensive Coverage**: Protects against modifying commands like `install`, `upgrade`, `uninstall`, `delete`, `rollback`

## Installation

### Via Helm Plugin Manager

```bash
# Install from local directory (for development)
helm plugin install /path/to/helm-safe

# Or install from git repository (when published)
helm plugin install https://github.com/bjrooney/helm-safe
```

### Manual Installation

1. Clone this repository
2. Run `make dev-install` to build and install locally
3. Or copy the plugin directory to `$(helm env HELM_PLUGINS)/safe`

### Build from Source

```bash
git clone https://github.com/bjrooney/helm-safe.git
cd helm-safe
make build
# Binary will be available at bin/helm-safe
```

## Usage

Replace your modifying Helm commands with `helm safe`:

```bash
# Instead of:
helm install my-app ./chart

# Use:
helm safe install my-app ./chart --namespace my-ns --kube-context dev

# Instead of:
helm upgrade my-app ./chart

# Use:
helm safe upgrade my-app ./chart --namespace my-ns --kube-context dev

# Instead of:
helm uninstall my-app

# Use:
helm safe uninstall my-app --namespace my-ns --kube-context dev
```

## Commands Covered

### Modifying Commands (require safety checks)
- `install` - Install a chart
- `upgrade` - Upgrade a release
- `uninstall`/`delete` - Uninstall a release
- `rollback` - Rollback a release
- `create` - Create a new chart
- `package` - Package a chart
- `dependency update` - Update chart dependencies
- `dependency build` - Build chart dependencies
- `plugin install/update/uninstall` - Manage plugins
- `repo add/update/remove` - Manage repositories
- `push` - Push to registry

### Safe Commands (pass through without checks)
- `list`/`ls` - List releases
- `status` - Show release status
- `get` - Get release information
- `history` - Show release history
- `show` - Show chart information
- `test` - Run tests
- `lint` - Lint a chart
- `verify` - Verify a chart
- `version` - Show version
- `help` - Show help
- `search` - Search for charts
- `pull` - Pull a chart
- `template` - Render templates
- `completion` - Generate completion scripts
- `env` - Show environment

## Safety Features

### Required Flags
For all modifying commands, helm-safe requires:
- `--namespace` (or `-n`) - Explicit namespace specification
- `--kube-context` - Explicit Kubernetes context specification

These can also be provided via environment variables:
- `HELM_NAMESPACE` - Default namespace
- `HELM_KUBECONTEXT` - Default context

### Interactive Confirmation
Before executing modifying commands, helm-safe shows:
- The full command to be executed
- Target Kubernetes context
- Target namespace
- Special production warnings if applicable

### Production Context Detection
helm-safe automatically detects production-like contexts and shows additional warnings for contexts containing:
- "prod"
- "production" 
- "live"
- "prd"

## Development

### Prerequisites
- Go 1.21 or later
- Helm 3.x
- kubectl (for context validation)

### Building
```bash
# Build for current platform
make build

# Build for all platforms
make cross-build

# Run tests
make test

# Install for development
make dev-install

# Uninstall
make dev-uninstall
```

### Testing
```bash
# Run unit tests
make test

# Manual testing
helm safe install --help
helm safe list  # Should pass through
helm safe install my-app ./chart  # Should require flags
```

## Configuration

helm-safe respects the following environment variables:
- `HELM_NAMESPACE` - Default namespace
- `HELM_KUBECONTEXT` - Default Kubernetes context
- `HELM_BIN` - Path to helm binary (defaults to "helm")
- All other standard Helm environment variables

## Examples

### Basic Usage
```bash
# This will require confirmation and safety checks
helm safe install wordpress bitnami/wordpress \
  --namespace wordpress \
  --kube-context staging-cluster

# This passes through without checks
helm safe list --all-namespaces
```

### Using Environment Variables
```bash
export HELM_NAMESPACE=default
export HELM_KUBECONTEXT=dev-cluster

# Now these flags are optional
helm safe install my-app ./chart
```

### Production Deployment
```bash
# Production context will trigger additional warnings
helm safe upgrade my-app ./chart \
  --namespace production \
  --kube-context prod-cluster
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Run `make test` and `make lint`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Inspiration

This plugin is inspired by [kubectl-safe](https://github.com/bjrooney/kubectl-safe), which provides similar safety features for kubectl commands.