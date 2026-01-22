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
export HCLOUD_TOKEN="your-hcloud-token"
export LETSENCRYPT_EMAIL="admin@your-domain.com"
export HETZNER_DNS_API_TOKEN="your-hetzner-dns-token"

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
    ├── variables.tf            # All shared variables (3 total)
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

### Platform Resources (`modules/platform-resources`)
- Cilium Gateway for ingress (`*.deliberate.cloud`)
- Hetzner DNS-01 certificate issuer
- TLS certificate management via cert-manager
- LoadBalancer configuration for external access

## Deployment Commands

### Full Cluster Deployment
```bash
# From repository root
cd terraform

# Environment variables approach (recommended)
export HCLOUD_TOKEN="your-token"
export LETSENCRYPT_EMAIL="admin@domain.com"
export HETZNER_DNS_API_TOKEN="your-dns-token"

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
- Clone this repository
- Install required tools via `mise install`

3. **Deploy Cluster**
   ```bash
   cd workload-cluster
   tofu init
   tofu plan -var="hcloud_token=$HCLOUD_TOKEN"
   tofu apply -var="hcloud_token=$HCLOUD_TOKEN"
   ```

4. **Access Cluster**
   - `kubeconfig` - Generated for kubectl access
   - `talosconfig` - Generated for Talos OS management

## Architecture

The hcloud-k8s module automatically provisions:
- TalOS OS servers (control planes + workers)
- Kubernetes bootstrap and configuration
- Cilium CNI for networking
- Hetzner Cloud Controller Manager
- Hetzner CSI for persistent storage
- Metrics Server, Cert Manager, Cluster Autoscaler
- Longhorn distributed storage

## Module Details

**Source**: [hcloud-k8s/kubernetes/hcloud](https://registry.terraform.io/modules/hcloud-k8s/kubernetes/hcloud/latest)

The module handles the complete cluster lifecycle using Packer for TalOS image creation and Terraform for infrastructure management.

## Environment Variables

Required in `.env`:
```bash
HCLOUD_TOKEN=your_hetzner_cloud_api_token
```

## Security Notes

- Never commit `.env` files or API tokens
- State files are excluded from git
- Sensitive Terraform variables marked appropriately
