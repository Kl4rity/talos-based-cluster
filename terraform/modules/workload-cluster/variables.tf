variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Base domain for the cluster (e.g., 'deliberate.cloud')"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for External DNS"
  sensitive   = true
}
