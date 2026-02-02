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
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "workload_cluster" {
  source               = "./modules/workload-cluster"
  hcloud_token         = var.hcloud_token
  domain_name          = var.domain_name
  cloudflare_api_token = var.cloudflare_api_token
}

module "platform_resources" {
  source               = "./modules/platform-resources"
  letsencrypt_email    = var.letsencrypt_email
  cloudflare_api_token = var.cloudflare_api_token
  domain_name          = var.domain_name

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
