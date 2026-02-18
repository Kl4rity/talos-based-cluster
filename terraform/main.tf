terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source = "hashicorp/helm"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "workload_cluster" {
  source               = "./modules/workload-cluster"
  hcloud_token         = var.hcloud_token
  domains              = var.domains
  cloudflare_api_token = var.cloudflare_api_token
}

# Generate secure GitLab root password if not provided
resource "random_password" "gitlab_root_password" {
  count = var.enable_gitlab && var.gitlab_root_password == null ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

# Generate secure server root password if not provided
resource "random_password" "gitlab_server_root_password" {
  count = var.enable_gitlab && var.gitlab_server_root_password == null ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

# Generate secure GitLab runner registration token
resource "random_password" "gitlab_runner_registration_token" {
  count = var.enable_gitlab ? 1 : 0

  length  = 32
  special = false
}

module "gitlab_server" {
  source                    = "./modules/gitlab-server"
  enable_gitlab             = var.enable_gitlab
  hcloud_token              = var.hcloud_token
  domains                   = var.domains
  server_type               = var.gitlab_server_type
  location                  = var.gitlab_server_location
  volume_size               = var.gitlab_volume_size
  gitlab_root_password      = var.gitlab_root_password != null ? var.gitlab_root_password : (var.enable_gitlab ? random_password.gitlab_root_password[0].result : "")
  root_password             = var.gitlab_server_root_password != null ? var.gitlab_server_root_password : (var.enable_gitlab ? random_password.gitlab_server_root_password[0].result : "")
  letsencrypt_email         = var.letsencrypt_email
  runner_registration_token = var.enable_gitlab ? random_password.gitlab_runner_registration_token[0].result : ""
  gitlab_image_tag          = var.gitlab_image_tag
}

module "platform_resources" {
  source                 = "./modules/platform-resources"
  letsencrypt_email      = var.letsencrypt_email
  cloudflare_api_token   = var.cloudflare_api_token
  domains                = var.domains
  grafana_admin_password = var.grafana_admin_password

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  depends_on = [module.workload_cluster]
}

provider "kubernetes" {
  config_path = "${path.module}/kubeconfig"
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/kubeconfig"
  }
}

# Outputs for GitLab
output "gitlab_url" {
  description = "GitLab web interface URL"
  value       = module.gitlab_server.gitlab_url
}

output "gitlab_registry_url" {
  description = "GitLab container registry URL"
  value       = module.gitlab_server.registry_url
}

output "gitlab_server_ip" {
  description = "GitLab server IP address"
  value       = module.gitlab_server.server_ipv4
}

output "gitlab_root_password" {
  description = "GitLab root password (if auto-generated)"
  value       = var.enable_gitlab && var.gitlab_root_password == null ? random_password.gitlab_root_password[0].result : "User provided - check your secrets"
  sensitive   = true
}

output "gitlab_server_root_password" {
  description = "GitLab server root password for console access (if auto-generated)"
  value       = var.enable_gitlab && var.gitlab_server_root_password == null ? random_password.gitlab_server_root_password[0].result : "User provided - check your secrets"
  sensitive   = true
}

output "gitlab_runner_registration_token" {
  description = "GitLab runner registration token"
  value       = var.enable_gitlab ? random_password.gitlab_runner_registration_token[0].result : null
  sensitive   = true
}

output "gitlab_debug_private_key" {
  description = "SSH private key for debugging the GitLab server"
  value       = module.gitlab_server.debug_ssh_private_key
  sensitive   = true
}

output "gitlab_k3s_admin_cert" {
  description = "K3s admin client certificate for GitLab node"
  value       = module.gitlab_server.k3s_admin_cert
  sensitive   = true
}

output "gitlab_k3s_admin_key" {
  description = "K3s admin client key for GitLab node"
  value       = module.gitlab_server.k3s_admin_key
  sensitive   = true
}

output "gitlab_k3s_ca_cert" {
  description = "K3s cluster CA certificate for GitLab node"
  value       = module.gitlab_server.k3s_ca_cert
  sensitive   = true
}
