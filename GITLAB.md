# GitLab CE Integration Guide

This guide explains how to use the GitLab CE instance deployed outside the Talos cluster.

## Architecture

GitLab CE runs on a **separate Hetzner server** (not in the Kubernetes cluster) to avoid the DNS hairpinning/split-horizon issues that occur with in-cluster registries. DNS is managed automatically via external-dns from the Kubernetes cluster.

## Deployment

GitLab is deployed when `enable_gitlab = true` (default). The module creates:

1. **Hetzner Server** (CPX31 by default) running Ubuntu 22.04
2. **Hetzner Volume** (100GB by default) mounted at `/var/opt/gitlab`
3. **Firewall** allowing ports 22, 80, 443
4. **DNS records** via external-dns for:
   - `gitlab.{domain}` - GitLab UI/API
   - `registry.{domain}` - Container Registry

## URLs

After deployment, access GitLab at:
- **GitLab**: `https://gitlab.deliberate.cloud` (and `.tech`)
- **Registry**: `https://registry.deliberate.cloud` (and `.tech`)
- **Username**: `root`
- **Password**: Check Terraform outputs with `terraform output gitlab_root_password`

## Using the Container Registry

### 1. Create a Personal Access Token

1. Log into GitLab at `https://gitlab.deliberate.cloud`
2. Go to **User Settings → Access Tokens**
3. Create a token with `read_registry` and `write_registry` scopes
4. Save the token securely

### 2. Login to Registry from Local Machine

```bash
docker login registry.deliberate.cloud
# Username: your-gitlab-username
# Password: your-access-token
```

### 3. Push Images to Registry

```bash
# Tag your image
docker tag myapp:latest registry.deliberate.cloud/myproject/myapp:latest

# Push to GitLab registry
docker push registry.deliberate.cloud/myproject/myapp:latest
```

## Using GitLab Registry with Kubernetes

### Option 1: Using imagePullSecrets (Recommended)

Create a registry secret in your namespace:

```bash
kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.deliberate.cloud \
  --docker-username=<your-gitlab-username> \
  --docker-password=<your-access-token> \
  --namespace=<your-namespace>
```

Reference in your deployments:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: registry.deliberate.cloud/myproject/myapp:latest
      imagePullSecrets:
      - name: gitlab-registry
```

### Option 2: Configure Talos Nodes (Node-level Auth)

Add registry configuration to Talos machine config:

```yaml
machine:
  registries:
    config:
      registry.deliberate.cloud:
        auth:
          username: <your-gitlab-username>
          password: <your-access-token>
```

Apply with:
```bash
talosctl edit machineconfig --nodes <node-ips>
```

This allows pulling images without imagePullSecrets.

## GitLab CI/CD with Kubernetes

### Deploy GitLab Runners in Cluster

```bash
helm repo add gitlab https://charts.gitlab.io
helm install gitlab-runner gitlab/gitlab-runner \
  --namespace gitlab-runner --create-namespace \
  --set gitlabUrl=https://gitlab.deliberate.cloud \
  --set runnerRegistrationToken=<token-from-gitlab>
```

### Example .gitlab-ci.yml

```yaml
stages:
  - build
  - deploy

variables:
  REGISTRY: registry.deliberate.cloud
  IMAGE: $REGISTRY/$CI_PROJECT_PATH:$CI_COMMIT_SHA

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $REGISTRY
    - docker build -t $IMAGE .
    - docker push $IMAGE

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/myapp myapp=$IMAGE
```

## Backup and Maintenance

### Security & Access

**SSH is disabled** on the GitLab server for security. The server is managed entirely through:
- **GitLab web UI**: For application configuration
- **Hetzner Console**: For emergency recovery access
- **Terraform**: For infrastructure changes

### Automatic Security Updates

The server is configured with `unattended-upgrades`:
- Daily security updates
- Automatic reboot at 3:00 AM if needed
- Unused dependencies removed automatically

### GitLab Upgrades

GitLab CE is configured to use the GitLab package repository. Upgrades happen automatically via unattended-upgrades for **patch releases** (e.g., 16.8.1 → 16.8.2).

#### Manual Major/Minor Version Upgrades

For major version upgrades (e.g., 16.x → 17.x), use Hetzner Console:

1. **Create volume snapshot first**:
   ```bash
   hcloud volume create-snapshot gitlab-data --description "Pre-upgrade backup"
   ```

2. **Access via Hetzner Console**:
   - Go to Hetzner Cloud Console
   - Select GitLab server
   - Click "Console" button (VNC access)

3. **Run upgrade commands**:
   ```bash
   # Check current version
   gitlab-rake gitlab:env:info

   # Update package list
   apt update

   # Upgrade GitLab
   apt install gitlab-ce

   # Reconfigure (happens automatically but can run manually)
   gitlab-ctl reconfigure
   ```

4. **Verify upgrade**:
   - Check GitLab UI still works
   - Verify version at https://gitlab.deliberate.cloud/help

#### Alternative: Recreate Server Strategy

For major upgrades, consider recreating the server:

1. Create volume snapshot
2. Set `enable_gitlab = false` in Terraform
3. Run `terraform apply` (destroys server, keeps volume)
4. Update Ubuntu image version if desired
5. Set `enable_gitlab = true`
6. Run `terraform apply` (creates new server, mounts existing volume)
7. GitLab will start with all existing data intact

### Backup GitLab Data

#### Volume Snapshots (Recommended)

Use Hetzner Cloud Console or CLI:
```bash
hcloud volume create-snapshot gitlab-data --description "Backup $(date +%Y-%m-%d)"
```

Snapshots are:
- **Incremental** (only changed blocks)
- **Instant** (no downtime)
- **Affordable** (~€0.013/GB/month)
- **Restorable** via Hetzner Console

#### GitLab Built-in Backups

Configure automatic backups in GitLab to Hetzner Object Storage:

1. Enable Object Storage in `/etc/gitlab/gitlab.rb`:
   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central',
     'aws_access_key_id' => 'YOUR_KEY',
     'aws_secret_access_key' => 'YOUR_SECRET',
     'endpoint' => 'https://fsn1.your-objectstorage.com'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'gitlab-backups'
   ```

2. Schedule via cron (GitLab will handle this automatically)

### Restore from Backup

#### From Volume Snapshot

1. Create new volume from snapshot in Hetzner Console
2. Update Terraform to use new volume ID or attach manually
3. Start GitLab server

#### From GitLab Backup

Access via Hetzner Console:
```bash
gitlab-backup restore BACKUP=<timestamp>
gitlab-ctl reconfigure
gitlab-ctl restart
```

## Terraform Variables

Customize GitLab deployment in `terraform.tfvars` or environment variables:

```hcl
enable_gitlab           = true
gitlab_server_type      = "cpx31"      # 4 vCPU, 8GB RAM
gitlab_server_location  = "nbg1"
gitlab_volume_size      = 100          # GB
gitlab_root_password    = "..."        # Optional, auto-generated if not provided
```

## DNS Management

DNS records are automatically created by external-dns running in the Kubernetes cluster. The platform-resources module creates Kubernetes Services with Endpoints pointing to the GitLab server IP, annotated for external-dns to pick up.

No manual DNS configuration required!

## Cost Estimate

- **Server (CPX31)**: ~€15/month
- **Volume (100GB)**: ~€5/month
- **Total**: ~€20/month

## Troubleshooting

### GitLab not accessible after deployment

1. Check server status: `hcloud server list`
2. Access via Hetzner Console (VNC)
3. Check GitLab status: `gitlab-ctl status`
4. View logs: `gitlab-ctl tail`
5. Check cloud-init progress: `tail -f /var/log/cloud-init-output.log`

### DNS records not created

1. Check external-dns logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns`
2. Verify Services exist: `kubectl get svc -n default | grep gitlab`
3. Check Cloudflare DNS records in dashboard

### Registry authentication issues

1. Verify token has correct scopes (`read_registry`, `write_registry`)
2. Check GitLab registry is enabled: `gitlab-rails runner "Feature.enable(:container_registry)"`
3. Verify TLS certificate is valid: `curl -v https://registry.deliberate.cloud`

### Volume not mounted

1. Access via Hetzner Console (VNC)
2. Check mount: `df -h | grep gitlab`
3. View cloud-init logs: `cat /var/log/cloud-init-output.log`
4. Manually run setup: `/etc/gitlab-setup.sh`

## Security Considerations

### Why SSH is Disabled

SSH is disabled to reduce attack surface. The server is:
- **Immutable infrastructure**: Changes via Terraform, not manual SSH
- **Self-healing**: Automatic security updates handle patching
- **Accessible**: Hetzner Console provides emergency VNC access
- **Monitored**: GitLab has built-in monitoring/logging

### Emergency Access

If you need emergency access:
1. Go to Hetzner Cloud Console
2. Select the GitLab server
3. Click "Console" button (opens VNC terminal in browser)
4. Login credentials are managed by cloud-init (root login disabled by default)

### Enabling SSH (Not Recommended)

If you absolutely need SSH:

1. Modify `cloud-init.yaml`:
   ```yaml
   ssh_pwauth: false  # Keep password auth disabled
   disable_root: false  # Allow root if needed
   ```

2. Add SSH key variable to module

3. Update firewall to allow port 22

4. Apply with `terraform apply`

**Warning**: This increases attack surface. Consider using SSH only temporarily for debugging.
