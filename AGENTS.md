# AGENTS.md - Agent Guidelines for talos-based-cluster

## Overview
This repository manages a Talos-based Kubernetes cluster deployment on Hetzner Cloud using OpenTofu, Packer, Helm, and Kustomize. All tools are managed via mise.

## Tool Installation
```bash
mise install
```

## Build/Deploy Commands

### OpenTofu (Infrastructure)
All OpenTofu operations are run from component-specific directories (e.g., `hetzner/load-balancer/`, `hetzner/compute/`, `hetzner/traefik-lb/`):

```bash
cd hetzner/load-balancer  # or hetzner/compute/ or hetzner/traefik-lb/
tofu init
tofu plan -var="hcloud_token=$HCLOUD_TOKEN"
tofu apply -var="hcloud_token=$HCLOUD_TOKEN"
tofu validate
tofu fmt -check
```

### Packer (Image Snapshot)
```bash
cd hetzner/snapshot
packer init hcloud.pkr.hcl
packer build hcloud.pkr.hcl
```

### Helm/Helmfile (Cluster Initialization)
```bash
cd cluster-infrastructure/helm
helmfile sync
helmfile status
```

### Talos Configuration
```bash
cd hetzner/talos
talosctl gen config talos-k8s-hcloud-tutorial https://${CONTROLPLANE_IP}:6443
talosctl validate --config controlplane.yaml --mode cloud
talosctl validate --config worker.yaml --mode cloud
```

## Code Style Guidelines

### OpenTofu/Terraform (.tf)
- **Indentation**: 2 spaces
- **Naming**: snake_case for resources, variables, and outputs
- **Variables**: Always include `type`, `description`, and `sensitive` (when applicable)
- **Default values**: Provide sensible defaults in variable blocks
- **Complex types**: Use `object({})` or `map()` for structured data
- **Outputs**: Include `description` for all outputs
- **Providers**: Use `~> X.Y` version constraints in required_providers
- **Resource naming**: Descriptive names using `resource_type_descriptive_name` pattern

### Bash Scripts
- **Shebang**: Always `#!/bin/bash`
- **Error handling**: Start with `set -euo pipefail`
- **Variable expansion**: Use double quotes around variables: `"$VAR"`
- **Validation**: Check required environment variables before execution
- **Exit codes**: Use `exit 1` on errors with descriptive messages
- **Comments**: Brief comments for non-obvious operations

### YAML Files
- **Kubernetes manifests**: 2-space indentation
- **Talos configs**: 4-space indentation
- **Comments**: Inline comments explaining configuration values
- **Labels**: Use `app.kubernetes.io/name` and `app.kubernetes.io/component` conventions
- **Kustomize**: Keep resources in separate files, reference in kustomization.yaml

### HCL (Packer)
- **Indentation**: 2 spaces
- **Variables**: snake_case with `type`, `default`
- **Version constraints**: Use `~> X.Y` format (e.g., `~> 1`)
- **Source blocks**: Use descriptive source names matching the builder

### Helmfile
- **Defaults**: Set `wait: true`, `timeout: 600`, `atomic: true`
- **Hooks**: Use presync hooks for pre-deployment kubectl operations
- **Namespace**: Always specify `createNamespace: true` when needed

## File Organization
- Each infrastructure component in separate directory under `hetzner/`
- `terraform.tfvars` for variable values (not committed)
- Keep state files in component directories (not committed)
- Cluster manifests in `cluster-infrastructure/` separated by technology

## Environment Variables
Required variables (set in `.env` or export):
- `HCLOUD_TOKEN` - Hetzner Cloud API token
- `IMAGE_ID` - Talos OS image ID for compute
- `CONTROLPLANE_IP` - Control plane load balancer IP

## Security Notes
- Never commit `.env` files
- Mark sensitive variables with `sensitive = true` in Terraform
- Use SOPS for encrypted secrets when needed
- Never commit `terraform.tfstate` files
- Protect API tokens at all costs

## Deployment Order
1. Create Talos image snapshot with packer (`hetzner/snapshot/`)
2. Deploy control plane load balancer (`hetzner/load-balancer/`)
3. Deploy Traefik load balancer (`hetzner/traefik-lb/`)
4. Deploy compute nodes (`hetzner/compute/deploy.sh`)
5. Set `CONTROLPLANE_IP` environment variable
6. Generate and validate Talos configs (`hetzner/talos/`)
7. Initialize cluster with Talos tutorial steps
8. Install Helm charts (`cluster-infrastructure/helm/install.sh`)

## Best Practices
- Always review `tofu plan` output before applying
- Use label selectors for load balancer targets instead of explicit IPs
- Keep Talos configs in sync between controlplane and worker where applicable
- Validate configurations before applying
- Use version pinning for Helm charts and Packer plugins
