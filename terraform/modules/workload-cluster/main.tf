terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

locals {
  # Extract the first part of the domain to use as the cluster identifier
  # e.g., "deliberate.cloud" -> "deliberate"
  cluster_identifier = split(".", var.domain_name)[0]
}

module "kubernetes" {
  source  = "hcloud-k8s/kubernetes/hcloud"
  version = "3.20.1"

  cluster_name = "${local.cluster_identifier}-cluster"
  hcloud_token = var.hcloud_token

  cluster_kubeconfig_path  = "kubeconfig"
  cluster_talosconfig_path = "talosconfig"

  cluster_domain    = var.domain_name
  kube_api_hostname = "kube.${var.domain_name}"

  cert_manager_enabled       = true
  cilium_gateway_api_enabled = true
  ingress_nginx_enabled      = false
  longhorn_enabled = true
  longhorn_default_storage_class = true

  control_plane_nodepools = [
    {
      name     = "control"
      type     = "cax11"
      location = "fsn1"
      count    = 1
    }
  ]

  worker_nodepools = [
    {
      name     = "worker"
      type     = "cax11"
      location = "fsn1"
      count    = 2
    }
  ]

  firewall_use_current_ipv4      = true
  kube_api_load_balancer_enabled = true
}
