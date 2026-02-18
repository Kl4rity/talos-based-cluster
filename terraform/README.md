# Talos-based Kubernetes Cluster

A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with staged commands.
1. Deploy the workload-cluster
2. Deploy the platform-resources

## Quick Start
```bash
export TF_VAR_hcloud_token="your-hcloud-token"
export TF_VAR_letsencrypt_email="admin@your-domain.com"
export TF_VAR_cloudflare_api_token="your-cloudflare-token"
