variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address for Let's Encrypt certificate notifications"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token for DNS-01 challenges"
  sensitive   = true
}

variable "domains" {
  type        = list(string)
  description = "Domains served by this cluster. The first domain is the primary (used for naming and default routes). Each domain gets its own TLS certificate and gateway listeners."
  default     = ["deliberate.cloud", "deliberate.tech"]

  validation {
    condition     = length(var.domains) > 0
    error_message = "At least one domain must be provided."
  }
}

variable "harbor_admin_password" {
  type        = string
  description = "Admin password for Harbor registry. If not provided, a secure random password will be generated."
  sensitive   = true
  default     = null
}
