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
