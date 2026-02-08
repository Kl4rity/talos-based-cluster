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

variable "domain_name" {
  type        = string
  description = "Base domain for the cluster (e.g., 'deliberate.cloud', 'acme.com'). Used for DNS, TLS, and resource naming."
  default     = "deliberate.cloud"
}

variable "harbor_admin_password" {
  type        = string
  description = "Admin password for Harbor registry. If not provided, a secure random password will be generated."
  sensitive   = true
  default     = null
}
