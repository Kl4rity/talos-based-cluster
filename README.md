# Talos-based Kubernetes Cluster on Hetzner Cloud

A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with a single command.

The goal of this repository is to create an opinionated cluster deployment which provides any interested user with a solid starting point which includes all the basics one can expect. This is a work in progress - building up from the basics to convenience features:

- Compute ✅
- DNS ✅
- TLS Certificates ✅
- Container Registry 🚧
- Logging and Monitoring 🚧
- Tracing 🚧
- S3 Storage (Hetzner or Self-Hosted) 🚧
- Cloud Native Postgress 🚧
- ArgoCD? 🚧
- ... ?

## Why Talos on Hetzner?

### Customer Demand
Many customers prefer EU-based hosting over hyperscalers for data sovereignty and emotional reasons. Hetzner provides excellent price to performance with German/EU data residency.

### Portability
Kubernetes gives you deployment flexibility - migrate between Hetzner, Scaleway, Exoscale, or hyperscalers without reworking your K8s resources.

### Cost
Hyperscalers have high margins. Hetzner offers competitive pricing while maintaining excellent performance and reliability.

## Quick Start

### Option 1: Environment Variables
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

### Known limitations
As of right now, deployment needs to happen in two phases on a fresh install:

# Phase 1: Create the cluster
```
tofu plan -target=module.workload_cluster -out=tfplan-cluster
tofu apply tfplan-cluster
```
# Phase 2: Deploy platform resources
```
tofu plan -out=tfplan-platform
tofu apply tfplan-platform
```

## Repository Structure

This is the **new unified approach**. The legacy `workload-cluster/` and `platform-resources/` directories are deprecated.

```
talos-based-cluster/
└── terraform/                    # 🆕 Unified configuration (use this)
    ├── main.tf                 # Root config with providers and modules
    ├── README.md             # This documentation
    └── modules/
        ├── workload-cluster/     # Core cluster infrastructure
        └── platform-resources/   # Platform resources

## Architecture

This configuration deploys:

### Core Infrastructure (`modules/workload-cluster`)
- Talos-based Kubernetes cluster on Hetzner Cloud
- Control plane nodes
- Worker nodes
- Cilium CNI with Gateway API enabled

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

## Prerequisites

- Hetzner Cloud account with API token
- Cloudflare account for DNS management (required for DNS-01 challenges)
- Clone this repository
- Install required tools via `mise install`

## Security Notes

- Never commit `.env` files or API tokens
- State files are excluded from git
- Sensitive Terraform variables marked appropriately
