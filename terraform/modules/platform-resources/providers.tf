terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source = "hashicorp/helm"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}