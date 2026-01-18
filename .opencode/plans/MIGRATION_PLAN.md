# Migration Plan: Declarative GitOps Architecture

## Executive Summary

**Objective:** Transform current imperative Talos/Kubernetes setup into a fully declarative, GitOps-driven architecture using hcloud-talos module and ArgoCD.

**Target Architecture:**
- Infrastructure: hcloud-talos Terraform module (v2.23.1+)
- Management: 1-node management cluster on Hetzner
- Workload: 3 control planes + 2 workers with private network + NAT
- GitOps: ArgoCD for continuous reconciliation
- Domain: cloud.deliberate.tech
- Images: Talos factory images (no Packer for custom builds)

**Key Benefits:**
- ✅ Zero shell scripts for cluster operations
- ✅ All infrastructure defined declaratively (HCL + YAML)
- ✅ Continuous reconciliation via ArgoCD
- ✅ Production-grade security (private network + NAT)
- ✅ Battle-tested hcloud-talos module (285 stars, 57 forks)
- ✅ Single Git repository as source of truth

---

## Current State Analysis

### Existing Components
```
talos-based-cluster/
├── hetzner/
│   ├── load-balancer/         # OpenTofu module (control plane LB)
│   ├── traefik-lb/          # OpenTofu module (ingress LB)
│   ├── compute/              # OpenTofu module (servers)
│   ├── snapshot/             # Packer (Talos image builds)
│   └── talos/               # Talos configs (manual generation)
├── cluster-infrastructure/
│   ├── helm/                # Helmfile (Traefik deployment)
│   └── kustomize/           # Gateway resources
├── scripts/                   # Empty directory
└── .tool-versions             # mise tooling
```

### Issues with Current Approach
- ❌ 3 imperative shell scripts (`deploy.sh`, `generate-config.sh`, `install.sh`)
- ❌ Manual orchestration across 3 separate OpenTofu modules
- ❌ No continuous reconciliation or self-healing
- ❌ Hard-coded secrets in configs (controlplane.yaml:7, worker.yaml:7)
- ❌ Packer required for image snapshots
- ❌ Manual dependency management (must deploy LBs before compute)

---

## Target State Architecture

### New Repository Structure
```
talos-based-cluster/
├── management-cluster/           # NEW: ArgoCD management cluster
│   ├── main.tf                  # Hetzner server definition
│   ├── outputs.tf               # Cluster connection details
│   └── bootstrap/               # ArgoCD installation manifests
├── workload-cluster/            # NEW: hcloud-talos module
│   ├── main.tf                  # Module configuration
│   ├── versions.tf              # Version pins (Talos, K8s, Cilium)
│   └── terraform.tfvars.example # Template for secrets
├── applications/                 # NEW: Application manifests
│   ├── base/                    # Base ArgoCD ApplicationSets
│   └── overlays/                # Environment-specific configs
├── argocd/                     # NEW: ArgoCD resources
│   ├── app-of-apps.yaml       # Root Application
│   └── projects.yaml            # Project definitions
└── .github/
    └── workflows/
        └── apply-infra.yml      # GitHub Actions for infra changes
```

### Component Mapping

| Current Component | Replacement | Technology |
|-----------------|------------|-------------|
| `hetzner/load-balancer/` | hcloud-talos module (built-in) | OpenTofu |
| `hetzner/traefik-lb/` | hcloud-talos module (built-in) | OpenTofu |
| `hetzner/compute/` | hcloud-talos module | OpenTofu |
| `hetzner/snapshot/` | Talos factory images (direct) | N/A |
| `hetzner/talos/generate-config.sh` | hcloud-talos module (auto-generated) | N/A |
| `cluster-infrastructure/helm/` | ArgoCD ApplicationSet | GitOps |
| `.env` file | ArgoCD Secrets (external-secrets-operator) | GitOps |

---

## Implementation Plan

### Phase 1: Management Cluster Bootstrap ✅

**Goal:** Create 1-node ArgoCD management cluster on Hetzner

**Steps:**

1. **Create Hetzner management server**
   - Server type: cax11 (€4/month)
   - Location: Choose based on latency (fsn1, nbg1, hel1)
   - OS: Ubuntu 24.04
   - SSH key: Existing or generate new one

2. **Install Kubernetes (k3s)**
   ```bash
   # Install k3s via k3sup for simplicity
   curl -sfL https://get.k3s.io | sh -
   ```

3. **Bootstrap ArgoCD**
   ```bash
   # Create namespace
   kubectl create namespace argocd

   # Install ArgoCD
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

   # Get admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
   ```

4. **Configure ArgoCD**
   - Set up repository webhook (or use polling mode)
   - Configure repository credentials
   - Create projects for workload and applications

**Checkpoint:** Management cluster running, ArgoCD accessible

---

### Phase 2: Prepare GitOps Infrastructure ✅

**Goal:** Set up Git repository structure and secrets

**Steps:**

1. **Create repository structure** (as shown in target state)

2. **Configure secrets management**
   - Install external-secrets-operator in management cluster
   - Configure GitOps store (GitHub secrets, HashiCorp Vault, or 1Password)

3. **Set up GitHub repository**
   - Enable GitHub Actions
   - Configure repository secrets:
     - `HCLOUD_TOKEN`: Hetzner API token
     - `ARGOCD_PASSWORD`: ArgoCD admin password
     - `SSH_PRIVATE_KEY`: For management cluster access

**Checkpoint:** GitOps infrastructure ready

---

### Phase 3: Migrate to hcloud-talos Module ✅

**Goal:** Replace existing OpenTofu modules with hcloud-talos

**Steps:**

1. **Create workload-cluster directory**
   ```bash
   mkdir -p workload-cluster
   cd workload-cluster
   ```

2. **Create main.tf with hcloud-talos module**
   ```hcl
   terraform {
     required_providers {
       hetznercloud = {
         source  = "hetznercloud/hcloud"
         version = "~> 1.33"
       }
     }
   }

   provider "hetznercloud" {
     token = var.hcloud_token
   }

   module "talos" {
     source = "hcloud-talos/talos/hcloud"
     version = "2.23.1"

     # Versions
     talos_version      = "v1.11.0"
     kubernetes_version = "1.30.3"
     cilium_version     = "1.16.2"

     # Basic configuration
     hcloud_token      = var.hcloud_token
     cluster_name      = "deliberate-cluster"
     cluster_domain    = "cloud.deliberate.tech"
     cluster_api_host  = "kube.cloud.deliberate.tech"
     datacenter_name   = "fsn1-dc14"

     # Network configuration (private + NAT)
     network_ipv4_cidr    = "10.0.0.0/16"
     node_ipv4_cidr       = "10.0.1.0/24"
     pod_ipv4_cidr        = "10.244.0.0/16"
     service_ipv4_cidr    = "10.96.0.0/12"

     # Control planes (HA)
     control_plane_count        = 3
     control_plane_server_type = "cax21"
     control_plane_allow_schedule = false

     # Workers
     worker_count       = 2
     worker_server_type = "cax21"

     # Firewall (use current IP for security)
     firewall_use_current_ip = true
   }

   # Outputs for ArgoCD
   output "kubeconfig" {
     value     = module.talos.kubeconfig
     sensitive = true
   }

   output "talosconfig" {
     value     = module.talos.talosconfig
     sensitive = true
   }
   ```

3. **Create versions.tf** (pin all versions)
   ```hcl
   # Pin specific versions for reproducibility
   ```

4. **Create terraform.tfvars.example**
   ```hcl
   hcloud_token = "your-hcloud-token-here"
   ```

5. **Delete old OpenTofu modules**
   ```bash
   rm -rf hetzner/load-balancer/
   rm -rf hetzner/traefik-lb/
   rm -rf hetzner/compute/
   rm -rf hetzner/snapshot/
   rm -rf hetzner/talos/
   ```

6. **Test configuration locally**
   ```bash
   tofu init
   tofu plan -var-file="terraform.tfvars"
   tofu apply -var-file="terraform.tfvars"
   ```

**Checkpoint:** hcloud-talos module configured and tested

---

### Phase 4: DNS Configuration ✅

**Goal:** Configure cloud.deliberate.tech domain records

**Steps:**

1. **Add DNS records to your DNS provider**
   ```
   Type: A
   Name: kube
   Value: <hcloud_load_balancer_public_ip>
   TTL: 300

   Type: A
   Name: *.cloud
   Value: <traefik_load_balancer_public_ip>
   TTL: 300
   ```

2. **Verify DNS resolution**
   ```bash
   dig kube.cloud.deliberate.tech +short
   ```

**Checkpoint:** DNS configured and resolving

---

### Phase 5: Deploy Workload Cluster via ArgoCD ✅

**Goal:** Deploy hcloud-talos module through GitOps

**Steps:**

1. **Create ArgoCD Application for Terraform**
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: workload-cluster-infra
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/your-org/talos-based-cluster.git
       targetRevision: main
       path: workload-cluster
     destination:
       server: https://kubernetes.default.svc
       namespace: terraform
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
         allowEmpty: false
   ```

2. **Install Terraform operator in ArgoCD**
   - Use tf-controller or similar Kubernetes-native Terraform execution

3. **Configure secrets for Terraform**
   ```bash
   kubectl create secret generic hcloud-token \
     --from-literal=hcloud_token=$HCLOUD_TOKEN \
     --namespace=terraform
   ```

4. **Push changes to Git**
   ```bash
   git add .
   git commit -m "feat: add hcloud-talos module"
   git push
   ```

5. **Watch ArgoCD sync cluster**
   - Access ArgoCD UI
   - Monitor Application sync
   - Verify cluster provisioning

**Checkpoint:** Workload cluster deployed via GitOps

---

### Phase 6: Migrate Applications to ArgoCD ✅

**Goal:** Replace Helmfile with ArgoCD ApplicationSets

**Steps:**

1. **Create ApplicationSet for Traefik**
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: ApplicationSet
   metadata:
     name: traefik
     namespace: argocd
   spec:
     generators:
       - git:
           repoURL: https://github.com/your-org/talos-based-cluster.git
           revision: main
           directories:
             - path: applications/base/traefik
     template:
       metadata:
         name: '{{path.basename}}'
       spec:
         project: default
         source:
           repoURL: https://github.com/your-org/talos-based-cluster.git
           targetRevision: main
           path: '{{path}}'
         destination:
           server: https://kubernetes.default.svc
           namespace: traefik
         syncPolicy:
           automated:
             prune: true
             selfHeal: true
   ```

2. **Create Traefik values in Git**
   ```yaml
   # applications/base/traefik/values.yaml
   service:
     enabled: true
     type: LoadBalancer
     annotations:
       load-balancer.hetzner.cloud/location: fsn1
   ```

3. **Migrate Gateway resources**
   - Copy existing Kustomize manifests to applications/base/gateway/
   - Update values to work with hcloud-talos networking

4. **Delete old Helmfile**
   ```bash
   rm -rf cluster-infrastructure/helm/
   ```

5. **Push and sync**
   ```bash
   git add .
   git commit -m "feat: migrate Traefik to ArgoCD"
   git push
   ```

**Checkpoint:** All applications managed via ArgoCD

---

### Phase 7: Cleanup and Validation ✅

**Goal:** Remove deprecated code and validate end-to-end

**Steps:**

1. **Delete deprecated files**
   ```bash
   rm -rf scripts/
   rm -f cluster-infrastructure/helm/install.sh
   rm -f hetzner/talos/generate-config.sh
   rm -f hetzner/compute/deploy.sh
   ```

2. **Update .gitignore**
   ```gitignore
   # Terraform state (managed by ArgoCD)
   .terraform/
   .terraform.lock.hcl
   *.tfstate
   *.tfstate.backup

   # Secrets
   *.tfvars
   terraform.tfvars

   # Generated configs
   kubeconfig*
   talosconfig*

   # ArgoCD
   .argocd/
   ```

3. **Update .tool-versions**
   ```toml
   argocd = "2.13.4"
   k3s = "1.32.1"
   opentofu = "1.8.1"
   kubectl = "1.31.0"
   talosctl = "1.8.0"
   ```

4. **Update README.md**
   - Document new architecture
   - Document deployment process
   - Document GitOps workflow

5. **Final validation**
   ```bash
   # Test cluster connectivity
   kubectl get nodes --context=cloud.deliberate.tech

   # Test application deployment
   kubectl apply -f test-deployment.yaml

   # Test ArgoCD sync
   # Make a change to application and verify auto-sync
   ```

**Checkpoint:** Migration complete, system validated

---

## Known Issues and Workarounds

### Issue 1: hcloud-talos requires Packer for initial image build
**Status:** Partially resolved
**Solution:**
- Use Talos factory images directly via hcloud-talos module
- Module can reference factory images without custom Packer builds
- Only use Packer if you need custom system extensions

### Issue 2: ArgoCD managing Terraform state
**Status:** Requires evaluation
**Solution options:**
1. **tf-controller** (Kubernetes-native Terraform execution)
2. **GitOps pattern**: Store Terraform state in Git, run via CI/CD
3. **Terragrunt**: Wrapper for Terraform with better GitOps support

**Recommendation:** Evaluate tf-controller first for simplicity

### Issue 3: Private network + NAT complexity
**Status:** Addressed by hcloud-talos module
**Workaround:** Module includes NAT router configuration, no manual work needed

### Issue 4: Registry.k8s.io rate limiting
**Status:** Known hcloud-talos issue #46
**Workaround:** Use Hetzner's mirror or configure image pull cache
**Note:** Check if still applies, may be resolved in newer versions

### Issue 5: ArgoCD access to workload cluster
**Status:** Requires configuration
**Solution:** Use external-secrets-operator to sync workload cluster kubeconfig to management cluster

---

## Prerequisites

### Tools to Install
```bash
mise install
```

**Required versions (in .tool-versions):**
- `argocd >= 2.13.0`
- `k3s >= 1.32.0`
- `opentofu >= 1.8.1`
- `kubectl >= 1.31.0`
- `talosctl >= 1.8.0`

### Hetzner Cloud Setup
1. Create project
2. Generate API token with read/write access
3. Configure network (will be created by hcloud-talos module)
4. Set up domain (cloud.deliberate.tech)

### GitHub Setup
1. Create repository (or use existing)
2. Enable GitHub Actions
3. Configure secrets:
   - `HCLOUD_TOKEN`
   - `ARGOCD_PASSWORD`
   - `SSH_PRIVATE_KEY`

---

## Implementation Order

### Sequential Phases

| Phase | Description | Dependencies | Estimated Time |
|--------|-------------|----------------|----------------|
| 1 | Management cluster bootstrap | Hetzner account, domain | 1 hour |
| 2 | GitOps infrastructure | Phase 1 complete | 30 min |
| 3 | Migrate to hcloud-talos | Phase 2 complete | 2 hours |
| 4 | DNS configuration | Phase 3 cluster IP available | 15 min |
| 5 | Deploy via ArgoCD | Phases 1-4 complete | 2 hours |
| 6 | Migrate applications | Phase 5 complete | 1 hour |
| 7 | Cleanup & validation | Phase 6 complete | 1 hour |

**Total Estimated Time:** 7.5 hours

### Parallel Opportunities

None recommended - phases have strict dependencies

---

## Success Criteria

### Technical Validation
- [ ] Management cluster running and accessible
- [ ] ArgoCD UI accessible and functional
- [ ] hcloud-talos module plans successfully
- [ ] Workload cluster provisions (3 CP + 2 workers)
- [ ] Private network + NAT configured correctly
- [ ] DNS records resolving (kube.cloud.deliberate.tech)
- [ ] kubectl can access workload cluster
- [ ] Traefik deployed and accessible
- [ ] ApplicationSet syncs correctly
- [ ] Git push triggers automatic sync

### Process Validation
- [ ] Zero shell scripts required for cluster operations
- [ ] All infrastructure defined in HCL or YAML
- [ ] ArgoCD continuously reconciles state
- [ ] Secrets managed securely (no hardcoded values)
- [ ] Documentation updated and accurate
- [ ] Team can replicate deployment from scratch

---

## Rollback Strategy

If any phase fails, rollback steps:

1. **Phase 1 failure (management cluster)**
   - Destroy Hetzner management server
   - Start over with different server type/location

2. **Phase 3 failure (hcloud-talos)**
   - Keep old OpenTofu modules as backup
   - Revert to old modules in Git
   - Debug hcloud-talos configuration

3. **Phase 5 failure (ArgoCD deployment)**
   - Destroy workload cluster via talosctl/tofu
   - Revert to manual deployment
   - Debug ArgoCD configuration

4. **Phase 6 failure (application migration)**
   - Keep Helmfile as backup
   - Revert to Helmfile deployment
   - Debug ApplicationSet configuration

**Rollback command:**
```bash
git revert HEAD  # Revert last migration commit
# Apply old configuration manually
```

---

## Next Steps After Migration

1. **Observability:** Add Prometheus/Grafana via ArgoCD
2. **Backup:** Configure Velero for cluster backups
3. **CI/CD:** Add GitHub Actions for automated testing
4. **Monitoring:** Add notification hooks (Slack/email) for ArgoCD syncs
5. **Documentation:** Create runbooks for common operations
6. **Multi-cluster:** Extend architecture for additional clusters

---

## References

- [hcloud-talos module](https://github.com/hcloud-talos/terraform-hcloud-talos)
- [ArgoCD documentation](https://argoproj.github.io/argo-cd/)
- [Talos documentation](https://www.talos.dev/v1.9/)
- [Hetzner Cloud CCM](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Cilium CNI](https://cilium.io/)

---

## Appendix: File Templates

### workload-cluster/versions.tf
```hcl
# Pin all versions for reproducibility

# Talos version
variable "talos_version" {
  type    = string
  default = "v1.11.0"
}

# Kubernetes version
variable "kubernetes_version" {
  type    = string
  default = "1.30.3"
}

# Cilium version
variable "cilium_version" {
  type    = string
  default = "1.16.2"
}

# hcloud-talos module version
variable "module_version" {
  type    = string
  default = "2.23.1"
}
```

### argocd/app-of-apps.yaml
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  description: Default project for all applications
  sourceRepos:
    - repoURL: https://github.com/your-org/talos-based-cluster.git
  destinations:
    - namespace: '*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  namespaceResourceWhitelist:
    - group: '*'
      kind: '*'
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/talos-based-cluster.git
    targetRevision: main
    path: argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
```

---

**Document Version:** 1.0
**Last Updated:** 2025-01-18
**Author:** opencode
