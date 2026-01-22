# Talos-based Kubernetes Cluster

A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with a single command.

## Quick Start

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

| Variable | Description | Sensitive |
|-----------|-------------|------------|
| `hcloud_token` | Hetzner Cloud API token | ✅ |
| `letsencrypt_email` | Email for Let's Encrypt notifications | ❌ |
| `hetzner_dns_api_token` | Hetzner DNS API token for DNS-01 challenges | ✅ |

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