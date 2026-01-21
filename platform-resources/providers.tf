terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }
}

provider "kubernetes" {
  config_path    = "../workload-cluster/kubeconfig"
  config_context = "admin@deliberate-cluster"
}
