# Talos-based Kubernetes Cluster

A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with a single command.

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
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with your actual values
    ```

2. **Initialize and deploy:**
   ```bash
    cd terraform
    tofu init
    tofu apply -var-file="terraform.tfvars"
    ```

## Required Variables

| Variable | Environment Variable | Description | Sensitive |
|-----------|-------------------|-------------|------------|
| `hcloud_token` | `HCLOUD_TOKEN` | Hetzner Cloud API token | ✅ |
| `letsencrypt_email` | `LETSENCRYPT_EMAIL` | Email for Let's Encrypt notifications | ❌ |
| `hetzner_dns_api_token` | `HETZNER_DNS_API_TOKEN` | Hetzner DNS API token for DNS-01 challenges | ✅ |

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

## Outputs

- **Cluster Access**: `kubeconfig` and `talosconfig` files for cluster management
- **Network**: Public/private IPs for all nodes
- **Gateway**: External IP and configuration details
- **Storage**: Cilium encryption details

## Extensibility

The modular structure makes it easy to add new components:

```
terraform/modules/
├── workload-cluster/     # Core cluster (current)
├── platform-resources/   # Ingress/certificates (current)
├── container-registry/  # Harbor registry (future)
├── logging/             # Loki/Promtail (future)
└── s3-storage/          # MinIO/Hetzner Object Storage (future)
```

Simply add new module calls in `main.tf` when ready.

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

## Cleanup

After successful deployment, you can remove legacy directories:
```bash
rm -rf workload-cluster platform-resources
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

## Outputs

- **Cluster Access**: `kubeconfig` and `talosconfig` files for cluster management
- **Network**: Public/private IPs for all nodes
- **Gateway**: External IP and configuration details
- **Storage**: Cilium encryption details

## Extensibility

The modular structure makes it easy to add new components:

```
modules/
├── workload-cluster/     # Core cluster (current)
├── platform-resources/   # Ingress/certificates (current)
├── container-registry/  # Harbor registry (future)
├── logging/             # Loki/Promtail (future)
└── s3-storage/          # MinIO/Hetzner Object Storage (future)
```

Simply add new module calls in `main.tf` when ready.

## Cleanup

After successful deployment, you can remove the old directories:
```bash
rm -rf ../workload-cluster ../platform-resources
```