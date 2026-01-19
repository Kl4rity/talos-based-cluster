# Talos-based Kubernetes Cluster on Hetzner Cloud

This repository manages a Talos-based Kubernetes cluster deployment on Hetzner Cloud using the hcloud-k8s/kubernetes/hcloud module. All tools are managed via mise.

## Why Talos on Hetzner?

### Customer Demand
Many customers prefer EU-based hosting over hyperscalers for data sovereignty and emotional reasons. Hetzner provides excellent performance with German/EU data residency.

### Portability
Kubernetes gives you deployment flexibility - migrate between Hetzner, Scaleway, Exoscale, or hyperscalers without reworking your K8s resources.

### Cost
Hyperscalers have high margins. Hetzner offers competitive pricing while maintaining excellent performance and reliability.

## Quick Start

1. **Prerequisites**
   - Hetzner Cloud account with API token
   - Clone this repository

2. **Setup Environment**
   ```bash
   # Create .env file with your Hetzner token
   echo "HCLOUD_TOKEN=your_hetzner_token_here" > .env
   
   # Install required tools via mise
   mise install
   ```

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
