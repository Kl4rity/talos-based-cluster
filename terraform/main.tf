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
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

module "workload_cluster" {
  source = "./modules/workload-cluster"
  hcloud_token = var.hcloud_token
}

module "platform_resources" {
  source = "./modules/platform-resources"
  letsencrypt_email     = var.letsencrypt_email
  hetzner_dns_api_token = var.hetzner_dns_api_token

  providers = {
    kubernetes = kubernetes
  }
  depends_on = [module.workload_cluster]
}

provider "kubernetes" {
  config_path = "${path.module}/modules/workload-cluster/kubeconfig"
}