# AGENTS.md - Agent Guidelines for talos-based-cluster

## Overview
This repository manages a Talos-based Kubernetes cluster deployment on Hetzner Cloud using the hcloud-k8s/kubernetes/hcloud module. All tools are managed via mise.

## Tool Installation
```bash
mise install
```

## Build/Deploy Commands

### Workload Cluster (hcloud-k8s module)
All OpenTofu operations are run from the `workload-cluster/` directory:

```bash
cd workload-cluster
tofu init
tofu plan -var="hcloud_token=$HCLOUD_TOKEN"
tofu apply -var="hcloud_token=$HCLOUD_TOKEN"
tofu validate
tofu fmt -check
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

### HCL (Packer)
- **Indentation**: 2 spaces
- **Variables**: snake_case with `type`, `default`
- **Version constraints**: Use `~> X.Y` format (e.g., `~> 1`)
- **Source blocks**: Use descriptive source names matching the builder

## File Organization
- Workload cluster configuration in `workload-cluster/` directory
- `terraform.tfvars` for variable values (not committed)
- Keep state files in component directories (not committed)

## Environment Variables
Required variables (set in `.env` or export):
- `HCLOUD_TOKEN` - Hetzner Cloud API token

## Security Notes
- Never commit `.env` files
- Mark sensitive variables with `sensitive = true` in Terraform
- Use SOPS for encrypted secrets when needed
- Never commit `terraform.tfstate` files
- Protect API tokens at all costs

## Deployment Steps
1. Set the `HCLOUD_TOKEN` environment variable
2. Initialize OpenTofu in `workload-cluster/`
3. Apply the configuration: `tofu apply -var="hcloud_token=$HCLOUD_TOKEN"`
4. Access the cluster using the generated kubeconfig and talosconfig

## hcloud-k8s Module
The hcloud-k8s module automatically handles:
- Talos image creation via Packer
- Server provisioning (control planes and workers)
- Talos and Kubernetes bootstrap
- Cilium CNI installation
- Hcloud CCM/CSI
- Metrics Server
- Cert Manager
- Cluster Autoscaler
- Longhorn storage

Module: https://registry.terraform.io/modules/hcloud-k8s/kubernetes/hcloud/latest
