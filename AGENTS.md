# AGENTS.md - Agent Guidelines for talos-based-cluster

## Overview
This repository manages a Talos-based Kubernetes cluster deployment on Hetzner Cloud using a unified Terraform configuration with the hcloud-k8s/kubernetes/hcloud module. All tools are managed via mise.

## Tool Installation
```bash
mise install
```

Required tools versions (.tool-versions):
- opentofu 1.11.2
- helm 4.0.4
- helmfile 1.2.3
- packer 1.14.3
- sops 3.11.0

## Build/Deploy Commands

### Primary Commands (Unified Approach)
All operations are run from the `terraform/` directory:

```bash
cd terraform

# Initialize modules and providers
tofu init

# Plan with environment variables (recommended)
tofu plan

# Apply changes
tofu apply

# Validate configuration
tofu validate

# Format check (fails if not formatted)
tofu fmt -check

# Format code (auto-fixes)
tofu fmt

# Destroy infrastructure
tofu destroy

# Target specific modules
tofu apply -target=module.workload_cluster
tofu apply -target=module.platform_resources
```

### Testing and Validation
```bash
# Validate all Terraform files
tofu validate

# Check formatting
tofu fmt -check

# Plan to detect configuration errors
tofu plan -detailed-exitcode
```

### Legacy Commands (Deprecated)
The `workload-cluster/` directory approach is deprecated. Use the unified `terraform/` configuration instead.

## Code Style Guidelines

### OpenTofu/Terraform (.tf)
- **Indentation**: 2 spaces (no tabs)
- **Naming**: snake_case for resources, variables, and outputs
- **Variables**: Always include `type`, `description`, and `sensitive` (when applicable)
- **Default values**: Provide sensible defaults in variable blocks
- **Complex types**: Use `object({})` or `map()` for structured data
- **Outputs**: Include `description` for all outputs
- **Providers**: Use `~> X.Y` version constraints in required_providers
- **Resource naming**: Descriptive names using `resource_type_descriptive_name` pattern
- **Module structure**: Separate main.tf, variables.tf, outputs.tf
- **Provider configuration**: Centralize in root module, pass to submodules

### HCL/Terraform Specific Patterns
- **Module calls**: Use explicit variable assignments, one per line
- **Data sources**: Include depends_on when needed for explicit dependencies
- **Resource ordering**: Use explicit dependencies with depends_on when implicit ordering isn't clear
- **Kubernetes manifests**: Use kubernetes_manifest resource for complex YAML structures
- **Sensitive data**: Always mark with `sensitive = true` and avoid in outputs

### Kubernetes YAML
- **Indentation**: 2 spaces
- **API versions**: Use current stable versions
- **Metadata**: Include name and namespace for all resources
- **Labels**: Use consistent labeling conventions (app.kubernetes.io/*)
- **Secrets**: Use kubernetes_manifest or separate YAML files for sensitive data

### Environment Variables
- **Naming**: UPPER_CASE with underscores
- **Files**: Store in `.env` (never committed)
- **Validation**: Check required variables before running tofu commands

## File Organization
```
terraform/                          # Primary configuration directory
├── main.tf                        # Root configuration with providers and modules
├── variables.tf                   # All shared variables
├── terraform.tfvars.example      # Example configuration
├── modules/
│   ├── workload-cluster/         # Core cluster infrastructure
│   └── platform-resources/       # Platform resources and networking
└── README.md                     # Documentation

# Generated files (not committed)
kubeconfig                        # Kubernetes access configuration
talosconfig                       # Talos OS management configuration
*.tfvars                          # Variable values
terraform.tfstate*                # State files
.terraform/                       # Provider cache
```

## Environment Variables
Required variables (set in `.env` or export):
- `HCLOUD_TOKEN` - Hetzner Cloud API token (sensitive)
- `LETSENCRYPT_EMAIL` - Email for Let's Encrypt certificates
- `HETZNER_DNS_API_TOKEN` - Hetzner DNS API token for DNS-01 challenges (sensitive)

## Security Notes
- Never commit `.env` files or API tokens
- Mark sensitive variables with `sensitive = true` in Terraform
- Use SOPS for encrypted secrets when needed
- Never commit `terraform.tfstate` files
- Generate kubeconfig and talosconfig locally, never commit them
- Validate all plans before applying with `tofu plan`

## Module Dependencies
- **workload_cluster**: Deploys the core Talos Kubernetes cluster using hcloud-k8s module
- **platform_resources**: Depends on workload_cluster, installs ingress, certificates, and DNS

## hcloud-k8s Module Details
The hcloud-k8s module (v3.20.1) automatically handles:
- Talos image creation via Packer
- Server provisioning (control planes and workers)
- Talos and Kubernetes bootstrap
- Cilium CNI with Gateway API
- Hetzner CCM/CSI integration
- Metrics Server, Cert Manager, Cluster Autoscaler
- Longhorn distributed storage

Module: https://registry.terraform.io/modules/hcloud-k8s/kubernetes/hcloud/latest

## Common Workflows
```bash
# Full cluster deployment
cd terraform
export HCLOUD_TOKEN="your-token"
export LETSENCRYPT_EMAIL="admin@domain.com"
export HETZNER_DNS_API_TOKEN="your-dns-token"
tofu init && tofu apply

# Platform-only updates (after cluster exists)
tofu apply -target=module.platform_resources

# Cluster-only updates
tofu apply -target=module.workload_cluster

# Clean destroy
tofu destroy
```
