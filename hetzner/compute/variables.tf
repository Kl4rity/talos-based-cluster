variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "image_id" {
  type        = number
  description = "Talos OS image ID for control plane servers"
}

variable "control_plane_config" {
  type = object({
    server_type = string
    labels      = map(string)
    locations   = list(string)
    name_prefix = string
  })
  description = "Configuration for control plane servers"
  default = {
    server_type = "cx21"
    labels = {
      type = "controlplane"
    }
    locations   = ["hel1", "fsn1", "nbg1"]
    name_prefix = "talos-control-plane-"
  }
}