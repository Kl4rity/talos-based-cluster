# Traefik Gateway API Integration

## Overview

This repository implements a complete Traefik Gateway API integration using Infrastructure as Code (IaC) principles. The setup ensures reproducible deployments with proper RBAC, GatewayClass, and load balancer configuration.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Internet       │───▶│  Traefik LB     │───▶│  Traefik Pod   │
│  (80/443)      │    │  (NodePort)    │    │  (Gateway API)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                         ┌─────────────────────────────────┐
                         │  HTTPRoute (echo-server)    │
                         └─────────────────────────────────┘
```

## IaC Components

### 1. Helm Configuration
**File**: `cluster-infrastructure/helm/values/traefik.yaml`

- **Static NodePorts**: Explicitly configured (31362/30377) 
- **Gateway API**: Enabled via Helm chart
- **RBAC**: Basic permissions handled by Helm chart
- **Node Placement**: Traefik runs on worker nodes only

### 2. Kustomize Resources
**Files**: `cluster-infrastructure/kustomize/`

- **GatewayClass**: Creates Traefik GatewayClass with proper controller name
- **RBAC**: Additional permissions for Gateway API resources  
- **Gateway**: HTTP/HTTPS listeners with proper configuration

### 3. Load Balancer Configuration  
**Files**: `hetzner/traefik-lb/`

- **Static Ports**: Configured to match Traefik NodePorts
- **Target Selection**: Worker nodes via label selector `type=worker`
- **Separation**: Dedicated LB for application traffic

## Deployment Sequence

1. **GatewayClass Creation**: `kustomize build kustomize/ | kubectl apply -f -`
2. **Traefik Deployment**: `helmfile sync` 
3. **Load Balancer**: `tofu apply -auto-approve`
4. **HTTPRoute Creation**: `kubectl apply -f echo-server.yaml`

## Port Configuration

| Component | Port | Type | Notes |
|-----------|-------|-------|-------|
| External HTTP | 80 | LB → NodePort | Internet access |
| External HTTPS | 443 | LB → NodePort | Internet access |
| Traefik HTTP | 31362 | NodePort | Static assignment |
| Traefik HTTPS | 30377 | NodePort | Static assignment |
| Echo Service | 80 | ClusterIP | Backend service |

## Validation

### Manual Validation
```bash
# Test through NodePort (direct)
curl http://<worker-ip>:31362/echo

# Test through Load Balancer (final)  
curl http://<traefik-lb-ip>/echo
```

### IaC Validation  
- ✅ Gateway API permissions configured
- ✅ Static NodePorts assigned  
- ✅ Load balancer targets worker nodes
- ✅ HTTPRoute correctly programmed

## Benefits of This Approach

1. **Reproducible**: All configuration managed in Git
2. **Static Ports**: No port conflicts or surprises
3. **RBAC**: Proper permissions via IaC
4. **Separation**: Control plane vs application traffic
5. **Scalable**: Easy to add new HTTPRoutes

## Troubleshooting

If services aren't accessible:

1. **Check Gateway Status**: `kubectl get gateway -n traefik`
2. **Verify NodePorts**: `kubectl get svc -n traefik`  
3. **Validate RBAC**: `kubectl describe clusterrole traefik-traefik`
4. **Load Balancer Targets**: Check Hetzner console or use `tofu show`

## Migration from Manual Fixes

The following manual steps have been codified into IaC:

| Manual Step | IaC Equivalent |
|-------------|----------------|
| Manual GatewayClass creation | `kustomize/gatewayclass.yaml` |
| Manual RBAC patching | `kustomize/traefik-rbac.yaml` |
| Port detection scripts | Static ports in Helm values |
| Manual NodePort updates | Pre-configured in `terraform.tfvars` |