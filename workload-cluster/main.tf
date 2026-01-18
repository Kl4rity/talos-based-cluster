terraform {
  required_providers {
    hetznercloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.33"
    }
  }
}

provider "hetznercloud" {
  token = var.hcloud_token
}

module "talos" {
  source = "hcloud-talos/talos/hcloud"
  version = "2.23.1"

  talos_version      = "v1.11.0"
  kubernetes_version = "1.30.3"
  cilium_version     = "1.16.2"

  hcloud_token      = var.hcloud_token
  cluster_name      = "deliberate-cluster"
  cluster_domain    = "cloud.deliberate.tech"
  cluster_api_host  = "kube.cloud.deliberate.tech"
  datacenter_name   = "fsn1-dc14"

  network_ipv4_cidr    = "10.0.0.0/16"
  node_ipv4_cidr       = "10.0.1.0/24"
  pod_ipv4_cidr        = "10.244.0.0/16"
  service_ipv4_cidr    = "10.96.0.0/12"

  control_plane_count        = 3
  control_plane_server_type = "cx22"
  control_plane_allow_schedule = false

  worker_count       = 2
  worker_server_type = "cx22"

  firewall_use_current_ip = true
  disable_arm        = true
}
