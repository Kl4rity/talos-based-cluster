variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "domains" {
  type        = list(string)
  description = "Domains served by this cluster. The first domain is the primary (used for cluster naming)."
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for External DNS"
  sensitive   = true
}
