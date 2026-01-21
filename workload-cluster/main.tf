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

module "kubernetes" {
  source  = "hcloud-k8s/kubernetes/hcloud"
  version = "3.20.1"

  cluster_name = "deliberate-cluster"
  hcloud_token = var.hcloud_token

  cluster_kubeconfig_path  = "kubeconfig"
  cluster_talosconfig_path = "talosconfig"

   cluster_domain     = "deliberate.cloud"
   kube_api_hostname  = "kube.deliberate.cloud"

   cert_manager_enabled       = true
   cilium_gateway_api_enabled = true

   control_plane_nodepools = [
    {
      name     = "control"
      type     = "cax11"
      location = "fsn1"
      count    = 3
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

   firewall_use_current_ipv4 = true
   kube_api_load_balancer_enabled = true
}
