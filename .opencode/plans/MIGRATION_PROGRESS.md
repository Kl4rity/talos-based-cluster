# Migration Progress Summary

## Completed Work

### Phase 1: Management Cluster Bootstrap ✅
- [x] Created Hetzner management server (cax11, Ubuntu 24.04)
  - Server IP: 91.99.94.64
  - Fully reproducible via OpenTofu provisioners
- [x] Installed k3s on management server
  - Version: 1.34.3+k3s1
  - Kubeconfig downloaded reproducibly
- [x] Bootstrapped ArgoCD on management cluster
  - Version: 3.2.5
  - Admin password: `v2AgQTnIUH301s30` (stored in secret)
  - All pods running successfully
- [x] Configured ArgoCD repository and projects
  - Created app-of-apps.yaml
  - Set up GitHub Actions workflow
  - GitOps structure in place

### Phase 2: GitOps Infrastructure ✅
- [x] Created GitOps repository structure
  - `.github/workflows/` - CI/CD pipeline
  - `argocd/` - ArgoCD configuration
  - `applications/` - Application manifests (ready for future use)
  - Updated .gitignore for sensitive files

### Phase 3: Workload Cluster Setup ⚠️
- [x] Created workload-cluster directory with hcloud-talos module
  - Module: hcloud-talos/talos/hcloud v2.23.1
  - Configuration for 3 control planes + 2 workers
  - Using x86 servers (cx22) instead of ARM (resolved ARM image issue)
  - Disabled ARM architecture to prevent image lookup errors

## Known Issues

### hcloud-talos Module Compatibility
**Status:** Compatibility issues detected with OpenTofu 1.11.3 and Helm provider

**Errors Encountered:**
1. ARM Image Resolution (RESOLVED)
   - Error: "no image found matching selection" for ARM images
   - Solution: Added `disable_arm = true` to module configuration

2. Helm Provider Data Sources (BLOCKING)
   - Error: "Provider produced invalid object" for helm_template data sources
   - Affects: `data.helm_template.hcloud_ccm` and `data.helm_template.cilium_default`
   - Cause: Incompatibility between hcloud-talos module and current provider versions

**Root Cause Analysis:**
- hcloud-talos module uses `hashicorp/helm` provider v3.1.1
- OpenTofu 1.11.3 may have compatibility issues with this Helm provider version
- The module may need updates to support latest OpenTofu/Helm versions

**Potential Solutions:**
1. Wait for hcloud-talos module update to support OpenTofu 1.11.3
2. Pin older OpenTofu/Helm versions compatible with hcloud-talos
3. Use alternative Terraform modules for Talos deployment
4. Manually implement infrastructure using native Hetzner resources

## Current Infrastructure State

### Management Cluster (91.99.94.64)
- **Type:** k3s (lightweight Kubernetes)
- **ArgoCD:** Running and healthy
- **Access:**
  ```bash
  export KUBECONFIG=management-cluster/bootstrap/kubeconfig
  kubectl get nodes
  ```
  ```bash
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  # Access UI at https://localhost:8080
  # Username: admin
  # Password: v2AgQTnIUH301s30
  ```

### Old Infrastructure (Destroyed)
- Deleted 4 Talos servers (3 control planes + 1 worker)
- Deleted 2 load balancers (controlplane, traefik-ingress)
- Freed up Hetzner resources for new deployment

## Next Steps

### Immediate Actions Required:
1. **Fix hcloud-talos compatibility**
   - Research hcloud-talos module issues with OpenTofu 1.11.3
   - Consider pinning to OpenTofu 1.7.0 (from plan recommendations)
   - Check for alternative modules or manual implementation

2. **Configure secrets management** (Phase 2-2)
   - Install external-secrets-operator on management cluster
   - Configure GitOps store for workload cluster secrets
   - Set up ArgoCD Secrets for workload cluster access

3. **Deploy workload cluster** (Phase 5 - after fixing compatibility)
   - Apply workload-cluster OpenTofu configuration
   - Configure DNS records for cloud.deliberate.tech
   - Install applications via ArgoCD

### Future Phases:
- Phase 4: DNS Configuration (after cluster deployment)
- Phase 6: Migrate applications to ArgoCD
- Phase 7: Cleanup and validation

## Files Created

```
talos-based-cluster/
├── .github/workflows/
│   └── apply-infra.yml          # GitHub Actions for CI/CD
├── management-cluster/
│   ├── main.tf                   # Hetzner server definition
│   ├── variables.tf               # Variables for management cluster
│   ├── outputs.tf                # Server connection details
│   ├── bootstrap/
│   │   ├── kubeconfig            # k3s cluster config
│   │   ├── argocd-ns.yaml       # ArgoCD namespace
│   │   ├── argocd-install.yaml   # ArgoCD installation manifest
│   │   └── install-argocd.sh    # Reproducible install script
│   └── terraform.tfvars.example  # Template for secrets
├── workload-cluster/
│   ├── main.tf                   # hcloud-talos module config
│   ├── variables.tf               # Variables for workload cluster
│   └── terraform.tfvars.example  # Template for secrets
├── argocd/
│   └── app-of-apps.yaml        # Root ArgoCD Application
└── applications/                  # Ready for application manifests
    ├── base/                     # Base application configs
    └── overlays/                 # Environment-specific configs
```

## Git Commits Made
1. `feat: add management cluster and ArgoCD bootstrap`
   - Created management-cluster infrastructure
   - Set up ArgoCD with reproducible scripts
   - Added GitHub Actions workflow

2. `feat: add workload-cluster hcloud-talos configuration`
   - Added hcloud-talos module setup
   - Resolved ARM image issues
   - Documented compatibility problems

## Environment Variables
**Required for deployment:**
- `HCLOUD_TOKEN` - Hetzner Cloud API token
- `ARGOCD_PASSWORD` - ArgoCD admin password
- `KUBECONFIG` - Management cluster kubeconfig (auto-generated)

**Current Values:**
- Management Cluster: 91.99.94.64
- ArgoCD Admin: admin / v2AgQTnIUH301s30
- Hetzner Token: Already configured (not committed to git)

## Validation Steps Performed
- [x] Management cluster provisioned via OpenTofu
- [x] k3s installed automatically via provisioner
- [x] ArgoCD deployed and pods running
- [x] Kubeconfig generated and downloaded
- [x] GitHub Actions workflow configured
- [x] Repository structure created
- [x] All secrets excluded from git via .gitignore
- [ ] Workload cluster deployed (blocked by compatibility)
- [ ] DNS records configured
- [ ] Applications synced via ArgoCD

## Commands Available

```bash
# Management cluster operations
cd management-cluster
tofu plan -var-file="terraform.tfvars"
tofu apply -var-file="terraform.tfvars"

# Access ArgoCD
export KUBECONFIG=management-cluster/bootstrap/kubeconfig
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Workload cluster operations (after fixing compatibility)
cd workload-cluster
tofu init
tofu plan -var-file="terraform.tfvars"
tofu apply -var-file="terraform.tfvars"

# GitOps workflow
git push origin main
# GitHub Actions will trigger automatically
```

---

**Last Updated:** 2026-01-18
**Status:** Phase 1 & 2 Complete | Phase 3 In Progress (Compatibility Issues)
**Next Critical Action:** Resolve hcloud-talos module compatibility with OpenTofu 1.11.3
