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

data "terraform_remote_state" "workload_cluster" {
  backend = "local"
  config = {
    path = "${path.module}/workload_cluster/terraform.tfstate"
  }
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
  host                   = data.terraform_remote_state.workload_cluster.outputs.kubeconfig_data.clusters[0].cluster.server
  client_certificate     = base64decode(data.terraform_remote_state.workload_cluster.outputs.kubeconfig_data.users[0].user.client-certificate-data)
  client_key             = base64decode(data.terraform_remote_state.workload_cluster.outputs.kubeconfig_data.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.workload_cluster.outputs.kubeconfig_data.clusters[0].cluster.certificate-authority-data)
  config_context         = data.terraform_remote_state.workload_cluster.outputs.kubeconfig_data.contexts[0].context.cluster
}