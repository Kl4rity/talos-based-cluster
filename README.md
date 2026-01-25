# Talos-based Kubernetes Cluster on Hetzner Cloud

A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with a single command.

## Why Talos on Hetzner?

### Customer Demand
Many customers prefer EU-based hosting over hyperscalers for data sovereignty and emotional reasons. Hetzner provides excellent performance with German/EU data residency.

### Portability
Kubernetes gives you deployment flexibility - migrate between Hetzner, Scaleway, Exoscale, or hyperscalers without reworking your K8s resources.

### Cost
Hyperscalers have high margins. Hetzner offers competitive pricing while maintaining excellent performance and reliability.

## Quick Start

### Option 1: Environment Variables (Recommended)
Set all required environment variables and run:

```bash
# Set environment variables (add to ~/.bashrc or .env)
export TF_VAR_hcloud_token="your-hcloud-token"
export TF_VAR_letsencrypt_email="admin@your-domain.com"
export TF_VAR_cloudflare_api_token="your-cloudflare-token"
export TF_VAR_domain_name="your-domain.com"

# Deploy
cd terraform
tofu init
tofu apply
```

### Option 2: Variables File
1. **Copy and configure variables:**
   ```bash
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    # Edit terraform/terraform.tfvars with your actual values
    ```

2. **Initialize and deploy:**
   ```bash
    cd terraform
    tofu init
    tofu apply -var-file="terraform/terraform.tfvars"
    ```

## Repository Structure

This is the **new unified approach**. The legacy `workload-cluster/` and `platform-resources/` directories are deprecated.

```
talos-based-cluster/
└── terraform/                    # 🆕 Unified configuration (use this)
    ├── main.tf                 # Root config with providers and modules
    ├── variables.tf            # All shared variables (4 total)
    ├── terraform.tfvars.example # Example configuration
    ├── README.md             # This documentation
    └── modules/
        ├── workload-cluster/     # Core cluster infrastructure
        └── platform-resources/   # Platform resources

    # Legacy directories (can remove after successful deployment):
    ├── workload-cluster/         # ❌ Deprecated
    └── platform-resources/       # ❌ Deprecated
```

## Architecture

This configuration deploys:

### Core Infrastructure (`modules/workload-cluster`)
- Talos-based Kubernetes cluster on Hetzner Cloud
- 3 control plane nodes (cax11, fsn1)
- 2 worker nodes (cax11, fsn1)
- Cilium CNI with Gateway API enabled
- Cert-Manager, Metrics Server, Longhorn storage, Cluster Autoscaler
- Hetzner CCM/CSI for cloud integration
- **Cluster Name**: Derived from domain (e.g., `acme.com` → `acme-cluster`)

### Platform Resources (`modules/platform-resources`)
- Cilium Gateway for ingress (`*.your-domain.com`)
- Hetzner DNS-01 certificate issuer
- TLS certificate management via cert-manager
- LoadBalancer configuration for external access
- **Gateway Name**: Derived from domain (e.g., `acme.com` → `acme-gateway`)

## Deployment Commands

### Full Cluster Deployment
```bash
# From repository root
cd terraform

# Environment variables approach (recommended)
export HCLOUD_TOKEN="your-token"
export LETSENCRYPT_EMAIL="admin@domain.com"
export CLOUDFLARE_API_TOKEN="your-cloudflare-token"
export TF_VAR_domain_name="your-domain.com"

tofu init
tofu apply
```

### Platform-Only Updates
If you only need to update platform resources (after initial deployment):
```bash
cd terraform
tofu apply -target=module.platform_resources
```

## Prerequisites

- Hetzner Cloud account with API token
- Cloudflare account for DNS management (required for DNS-01 challenges)
- Clone this repository
- Install required tools via `mise install`

## Security Notes

- Never commit `.env` files or API tokens
- State files are excluded from git
- Sensitive Terraform variables marked appropriately
