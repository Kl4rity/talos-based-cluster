variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "server_name" {
  type        = string
  description = "Name of the management server"
  default     = "argocd-management"
}

variable "server_type" {
  type        = string
  description = "Hetzner server type"
  default     = "cax11"
}

variable "location" {
  type        = string
  description = "Hetzner datacenter location"
  default     = "fsn1"
}

variable "image" {
  type        = string
  description = "Server image"
  default     = "ubuntu-24.04"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of SSH key in Hetzner"
  default     = "deliberate-key"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to SSH private key for provisioning"
  default     = "/home/deliberate/.ssh/id_ed25519"
}
