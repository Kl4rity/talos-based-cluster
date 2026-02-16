terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source = "hashicorp/helm"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

locals {
  primary_domain = var.domains[0]
  gitlab_url     = "https://gitlab.${local.primary_domain}"
  registry_url   = "https://registry.${local.primary_domain}"
}

# Hetzner Volume for GitLab data
resource "hcloud_volume" "gitlab_data" {
  count    = var.enable_gitlab ? 1 : 0
  name     = "gitlab-data"
  size     = var.volume_size
  location = var.location
  format   = "ext4"

  labels = {
    service = "gitlab"
  }
}

# Cloud-init configuration for GitLab installation
data "cloudinit_config" "gitlab" {
  count         = var.enable_gitlab ? 1 : 0
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init.yaml", {
      gitlab_hostname           = replace(local.gitlab_url, "https://", "")
      gitlab_url                = local.gitlab_url
      registry_url              = local.registry_url
      gitlab_root_password      = var.gitlab_root_password
      root_password             = var.root_password
      letsencrypt_email         = var.letsencrypt_email
      runner_registration_token = var.runner_registration_token
      volume_id                 = hcloud_volume.gitlab_data[0].id
      gitlab_image_tag          = var.gitlab_image_tag
      k3s_ca_cert               = tls_self_signed_cert.k3s_ca[0].cert_pem
      k3s_ca_key                = tls_private_key.k3s_ca[0].private_key_pem
    })
  }
}

# Generate a custom CA for the GitLab K3s node
resource "tls_private_key" "k3s_ca" {
  count     = var.enable_gitlab ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate SSH key for debugging
resource "tls_private_key" "debug_ssh" {
  count     = var.enable_gitlab ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "debug" {
  count      = var.enable_gitlab ? 1 : 0
  name       = "gitlab-debug-key"
  public_key = tls_private_key.debug_ssh[0].public_key_openssh
}

resource "tls_self_signed_cert" "k3s_ca" {
  count           = var.enable_gitlab ? 1 : 0
  private_key_pem = tls_private_key.k3s_ca[0].private_key_pem

  subject {
    common_name  = "k3s-ca"
    organization = "GitLab Node"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

# Generate admin client certificate for K3s
resource "tls_private_key" "k3s_admin" {
  count     = var.enable_gitlab ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "k3s_admin" {
  count           = var.enable_gitlab ? 1 : 0
  private_key_pem = tls_private_key.k3s_admin[0].private_key_pem

  subject {
    common_name  = "admin"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "k3s_admin" {
  count              = var.enable_gitlab ? 1 : 0
  cert_request_pem   = tls_cert_request.k3s_admin[0].cert_request_pem
  ca_private_key_pem = tls_private_key.k3s_ca[0].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.k3s_ca[0].cert_pem

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_encipherment",
  ]
}

# GitLab server
resource "hcloud_server" "gitlab" {
  count       = var.enable_gitlab ? 1 : 0
  name        = "gitlab-${local.primary_domain}"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"

  user_data = data.cloudinit_config.gitlab[0].rendered

  ssh_keys = var.enable_gitlab ? [hcloud_ssh_key.debug[0].id] : []

  labels = {
    service = "gitlab"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

# Attach volume to GitLab server
resource "hcloud_volume_attachment" "gitlab_data" {
  count     = var.enable_gitlab ? 1 : 0
  volume_id = hcloud_volume.gitlab_data[0].id
  server_id = hcloud_server.gitlab[0].id
  automount = false # We'll mount it manually to /var/opt/gitlab
}

# Firewall for GitLab server - SSH disabled for security
resource "hcloud_firewall" "gitlab" {
  count = var.enable_gitlab ? 1 : 0
  name  = "gitlab-firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "2222"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "gitlab" {
  count       = var.enable_gitlab ? 1 : 0
  firewall_id = hcloud_firewall.gitlab[0].id
  server_ids  = [hcloud_server.gitlab[0].id]
}

# Get Cloudflare zone IDs for each domain
data "cloudflare_zone" "domains" {
  for_each = var.enable_gitlab ? toset(var.domains) : []
  name     = each.value
}

# Create A records for gitlab.{domain}
resource "cloudflare_record" "gitlab" {
  for_each = var.enable_gitlab ? toset(var.domains) : []

  zone_id = data.cloudflare_zone.domains[each.value].id
  name    = "gitlab"
  content = hcloud_server.gitlab[0].ipv4_address
  type    = "A"
  ttl     = 300
  proxied = false

  comment = "GitLab CE server managed by Terraform"
}

# Create A records for registry.{domain}
resource "cloudflare_record" "registry" {
  for_each = var.enable_gitlab ? toset(var.domains) : []

  zone_id = data.cloudflare_zone.domains[each.value].id
  name    = "registry"
  content = hcloud_server.gitlab[0].ipv4_address
  type    = "A"
  ttl     = 300
  proxied = false

  comment = "GitLab Container Registry managed by Terraform"
}

# Wait for K3s API to be ready
resource "null_resource" "wait_for_k3s" {
  count = var.enable_gitlab ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      TIMEOUT=300
      ELAPSED=0
      until curl -k -s https://${hcloud_server.gitlab[0].ipv4_address}:6443/livez > /dev/null || [ $ELAPSED -ge $TIMEOUT ]; do
        echo "Waiting for K3s API at ${hcloud_server.gitlab[0].ipv4_address}:6443... ($ELAPSED/$TIMEOUT)"
        sleep 10
        ELAPSED=$((ELAPSED + 10))
      done
      if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "Timeout waiting for K3s API"
        exit 1
      fi
      echo "K3s API is reachable!"
    EOT
  }

  depends_on = [hcloud_server.gitlab, cloudflare_record.gitlab]
}

# Provider for the dedicated GitLab K3s instance
provider "helm" {
  alias = "gitlab_k3s"
  kubernetes = {
    host                   = length(hcloud_server.gitlab) > 0 ? "https://${hcloud_server.gitlab[0].ipv4_address}:6443" : ""
    client_certificate     = length(tls_locally_signed_cert.k3s_admin) > 0 ? tls_locally_signed_cert.k3s_admin[0].cert_pem : ""
    client_key             = length(tls_private_key.k3s_admin) > 0 ? tls_private_key.k3s_admin[0].private_key_pem : ""
    cluster_ca_certificate = length(tls_self_signed_cert.k3s_ca) > 0 ? tls_self_signed_cert.k3s_ca[0].cert_pem : ""
  }
}

# GitLab Helm Release on the dedicated K3s instance
resource "helm_release" "gitlab_ce" {
  count            = var.enable_gitlab ? 1 : 0
  provider         = helm.gitlab_k3s
  name             = "gitlab"
  repository       = "https://charts.gitlab.io/"
  chart            = "gitlab"
  version          = "8.11.1"
  namespace        = "gitlab"
  create_namespace = true
  timeout          = 900
  render_subchart_notes = true
  upgrade_install       = false
  wait                  = true
  atomic                = false
  dependency_update     = false
  force_update          = false
  recreate_pods         = false
  replace               = false
  skip_crds             = false
  take_ownership        = false
  reset_values          = false
  disable_webhooks      = false
  reuse_values          = false
  verify                = false
  lint                  = false
  max_history           = 0
  pass_credentials      = false
  wait_for_jobs         = false
  cleanup_on_fail       = false
  disable_crd_hooks     = false
  disable_openapi_validation = false

  values = [
    templatefile("${path.module}/values.yaml", {
      domain                    = replace(local.gitlab_url, "https://gitlab.", "")
      gitlab_url                = local.gitlab_url
      letsencrypt_email         = var.letsencrypt_email
      gitlab_root_password      = var.gitlab_root_password
      runner_registration_token = var.runner_registration_token
    })
  ]

  depends_on = [null_resource.wait_for_k3s]
}
