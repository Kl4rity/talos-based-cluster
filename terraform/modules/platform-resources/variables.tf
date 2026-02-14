variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS-01 challenges"
  type        = string
  sensitive   = true
}

variable "domains" {
  description = "Domains served by this cluster. The first domain is the primary (used for naming and default routes)."
  type        = list(string)
}

variable "harbor_admin_password" {
  description = "Admin password for Harbor registry"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_harbor" {
  description = "Enable Harbor container registry deployment"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = null
}
