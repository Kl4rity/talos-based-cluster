# Talos-based Kubernetes Cluster

A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with a single command.

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

## Required Variables

| Variable | Environment Variable | Description | Sensitive |
|-----------|-------------------|-------------|------------|
| `hcloud_token` | `TF_VAR_hcloud_token` | Hetzner Cloud API token | ✅ |
| `letsencrypt_email` | `TF_VAR_letsencrypt_email` | Email for Let's Encrypt notifications | ❌ |
| `cloudflare_api_token` | `TF_VAR_cloudflare_api_token` | Cloudflare API token for DNS-01 challenges | ✅ |
| `domain_name` | `TF_VAR_domain_name` | Base domain (e.g., "acme.com") | ❌ |

## Repository Structure

```
talos-based-cluster/
└── terraform/                    # 🆕 Unified configuration (use this)
    ├── main.tf                 # Root config with providers and modules
    ├── README.md             # This documentation
    └── modules/
        ├── workload-cluster/     # Core cluster infrastructure
        └── platform-resources/   # Platform resources
```

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
export TF_VAR_hcloud_token="your-hcloud-token"
export TF_VAR_letsencrypt_email="admin@your-domain.com"
export TF_VAR_cloudflare_api_token="your-cloudflare-token"
export TF_VAR_domain_name="your-domain.com"

tofu init
tofu apply
```
