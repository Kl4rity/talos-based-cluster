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
  }
}

locals {
  primary_domain = var.domains[0]
  gitlab_url     = "https://gitlab.${local.primary_domain}"
  registry_url   = "https://registry.${local.primary_domain}"
}

# Hetzner Volume for GitLab data
resource "hcloud_volume" "gitlab_data" {
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
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init.yaml", {
      gitlab_url                = local.gitlab_url
      registry_url              = local.registry_url
      gitlab_root_password      = var.gitlab_root_password
      root_password             = var.root_password
      letsencrypt_email         = var.letsencrypt_email
      runner_registration_token = var.runner_registration_token
    })
  }
}

# GitLab server
resource "hcloud_server" "gitlab" {
  name        = "gitlab-${local.primary_domain}"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-22.04"

  user_data = data.cloudinit_config.gitlab.rendered

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
  volume_id = hcloud_volume.gitlab_data.id
  server_id = hcloud_server.gitlab.id
  automount = false # We'll mount it manually to /var/opt/gitlab
}

# Firewall for GitLab server - SSH disabled for security
resource "hcloud_firewall" "gitlab" {
  name = "gitlab-firewall"

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
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "gitlab" {
  firewall_id = hcloud_firewall.gitlab.id
  server_ids  = [hcloud_server.gitlab.id]
}

# Get Cloudflare zone IDs for each domain
data "cloudflare_zone" "domains" {
  for_each = toset(var.domains)
  name     = each.value
}

# Create A records for gitlab.{domain}
resource "cloudflare_record" "gitlab" {
  for_each = toset(var.domains)

  zone_id = data.cloudflare_zone.domains[each.value].id
  name    = "gitlab"
  content = hcloud_server.gitlab.ipv4_address
  type    = "A"
  ttl     = 300
  proxied = false

  comment = "GitLab CE server managed by Terraform"
}

# Create A records for registry.{domain}
resource "cloudflare_record" "registry" {
  for_each = toset(var.domains)

  zone_id = data.cloudflare_zone.domains[each.value].id
  name    = "registry"
  content = hcloud_server.gitlab.ipv4_address
  type    = "A"
  ttl     = 300
  proxied = false

  comment = "GitLab Container Registry managed by Terraform"
}

# GitLab Runner deployed on the Kubernetes cluster
resource "helm_release" "gitlab_runner" {
  name             = "gitlab-runner"
  repository       = "https://charts.gitlab.io"
  chart            = "gitlab-runner"
  namespace        = "gitlab-runner"
  create_namespace = true
  version          = "0.72.1"

  values = [
    yamlencode({
      gitlabUrl = local.gitlab_url
      runnerRegistrationToken = var.runner_registration_token
      rbac = {
        create = true
      }
      runners = {
        privileged = true
        tags = "kubernetes,cluster"
        config = <<-EOT
          [[runners]]
            [runners.kubernetes]
              namespace = "gitlab-runner"
              image = "ubuntu:22.04"
              privileged = true
        EOT
      }
    })
  ]

  # Wait for GitLab server to be somewhat ready, though the runner will retry
  depends_on = [hcloud_server.gitlab, cloudflare_record.gitlab]
}
