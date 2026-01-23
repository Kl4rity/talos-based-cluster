# AGENTS.md - Agent Guidelines for talos-based-cluster

## Overview
This repository manages a Talos-based Kubernetes cluster on Hetzner Cloud using OpenTofu.
All infrastructure is defined in the `terraform/` directory using a unified configuration approach.

## Tooling
Tools are managed via `mise`. Ensure you have the following versions installed:
- opentofu 1.11.2
- helm 4.0.4
- helmfile 1.2.3
- packer 1.14.3
- sops 3.11.0

Run `mise install` to set up the environment.

## Build, Lint, and Test Commands

All commands must be run from the `terraform/` directory: `cd terraform`

### Validation & Linting
Run these before any commit to ensure code quality:
```bash
# Validate configuration syntax and consistency
tofu validate

# Check formatting (CI will fail if this passes with changes)
tofu fmt -check

# Automatically fix formatting
tofu fmt
```

### Running Tests (Planning)
In this Infrastructure-as-Code context, "testing" is primarily done via `tofu plan`.

**Running a "Single Test" (Targeted Plan):**
To test a specific module or resource without planning the entire cluster (useful for faster feedback):
```bash
# Test only the platform resources (ingress, certs, DNS)
tofu plan -target=module.platform_resources

# Test only the workload cluster core
tofu plan -target=module.workload_cluster
```

**Full Integration Test (Full Plan):**
To verify the entire configuration matches the desired state:
```bash
tofu plan
```

**Deep Validation:**
For a more thorough check that might catch API-level issues:
```bash
tofu plan -detailed-exitcode
```

## Code Style Guidelines

### Terraform/OpenTofu (.tf)
*   **Formatting**: strictly use `tofu fmt`. Indentation is 2 spaces.
*   **Naming Conventions**:
    *   Resources/Variables/Outputs: `snake_case` (e.g., `hcloud_token`).
    *   Resource Names: Descriptive and scoped (e.g., `hcloud_load_balancer.ingress_gateway`).
*   **Variables**:
    *   Must define `type`, `description`.
    *   Mark `sensitive = true` for secrets (tokens, passwords).
    *   Provide `default` values where sensible.
*   **Outputs**:
    *   Must include `description`.
    *   Do not output sensitive values in cleartext; mark as `sensitive = true`.
*   **Structure**:
    *   `main.tf`: Provider config and module calls.
    *   `variables.tf`: Input variable definitions.
    *   `outputs.tf`: Output definitions.
    *   `versions.tf`: Provider versions and Terraform settings.
*   **Modules**:
    *   Use the unified structure in `terraform/modules/`.
    *   Do not use the deprecated root-level directories (`workload-cluster/`, etc.).

### Kubernetes Manifests (YAML)
*   **Indentation**: 2 spaces.
*   **Labels**: Use standard `app.kubernetes.io/*` labels.
*   **Namespaces**: Always explicitly specify `namespace`.

### Error Handling & Safety
*   **Secrets**: NEVER commit secrets. Use `sops` or environment variables.
*   **State**: `terraform.tfstate` is local and gitignored.
*   **Destructive Actions**: Always run `tofu plan` before `tofu apply` or `tofu destroy`. Explain the impact to the user before running apply/destroy.

## Repository Architecture

### Directory Structure
```
terraform/
├── main.tf                 # Entry point
├── variables.tf            # Global variables
├── modules/
│   ├── workload-cluster/   # Talos nodes, CNI, CSI, CCM
│   └── platform-resources/ # Ingress, Cert-Manager, ExternalDNS
└── terraform.tfstate       # Local state (gitignored)
```

### Module Dependencies
1.  **workload-cluster**: The base layer. Sets up nodes and networking.
2.  **platform-resources**: Depends on `workload-cluster`. Configures `*.deliberate.cloud` ingress.

## Environment Variables
Required for all operations (set in `.env` or export):
*   `HCLOUD_TOKEN`: Hetzner Cloud API token.
*   `LETSENCRYPT_EMAIL`: Contact email for SSL.
*   `HETZNER_DNS_API_TOKEN`: DNS management token.

## Common Workflows

### Deploy Changes
```bash
cd terraform
tofu init
tofu plan -out=tfplan
tofu apply tfplan
```

### Platform-Only Update
```bash
cd terraform
tofu apply -target=module.platform_resources
```

### Destroy Infrastructure
```bash
cd terraform
tofu destroy
```
