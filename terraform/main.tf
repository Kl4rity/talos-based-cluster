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
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "workload_cluster" {
  source               = "./modules/workload-cluster"
  hcloud_token         = var.hcloud_token
  domains              = var.domains
  cloudflare_api_token = var.cloudflare_api_token
}

module "platform_resources" {
  source                = "./modules/platform-resources"
  letsencrypt_email     = var.letsencrypt_email
  cloudflare_api_token  = var.cloudflare_api_token
  domains               = var.domains
  harbor_admin_password = var.harbor_admin_password
  enable_harbor         = var.enable_harbor
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
