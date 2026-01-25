variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Base domain for the cluster (e.g., 'deliberate.cloud')"
}
