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
      k3s_token                 = random_password.k3s_token[0].result
      k3s_ca_cert               = tls_self_signed_cert.k3s_ca[0].cert_pem
      k3s_ca_key                = tls_private_key.k3s_ca[0].private_key_pem
    })
  }
}

# K3s Token for API authentication
resource "random_password" "k3s_token" {
  count   = var.enable_gitlab ? 1 : 0
  length  = 32
  special = false
}

# Generate a custom CA for the GitLab K3s node
resource "tls_private_key" "k3s_ca" {
  count     = var.enable_gitlab ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
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

# GitLab server
resource "hcloud_server" "gitlab" {
  count       = var.enable_gitlab ? 1 : 0
  name        = "gitlab-${local.primary_domain}"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"

  user_data = data.cloudinit_config.gitlab[0].rendered

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

# Provider for the dedicated GitLab K3s instance
provider "helm" {
  alias = "gitlab_k3s"
  kubernetes = {
    host                   = var.enable_gitlab ? "https://${hcloud_server.gitlab[0].ipv4_address}:6443" : ""
    token                  = var.enable_gitlab ? random_password.k3s_token[0].result : ""
    cluster_ca_certificate = var.enable_gitlab ? tls_self_signed_cert.k3s_ca[0].cert_pem : ""
  }
}

# GitLab Helm Release on the dedicated K3s instance
resource "helm_release" "gitlab_ce" {
  count            = var.enable_gitlab ? 1 : 0
  provider         = helm.gitlab_k3s
  name             = "gitlab"
  repository       = "https://charts.gitlab.io/"
  chart            = "gitlab"
  version          = "9.8.4"
  namespace        = "gitlab"
  create_namespace = true
  timeout          = 900

  values = [
    templatefile("${path.module}/values.yaml", {
      domain                    = replace(local.gitlab_url, "https://gitlab.", "")
      gitlab_url                = local.gitlab_url
      letsencrypt_email         = var.letsencrypt_email
      gitlab_root_password      = var.gitlab_root_password
      runner_registration_token = var.runner_registration_token
    })
  ]

  depends_on = [hcloud_server.gitlab]
}
