variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS-01 challenges"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Base domain for the cluster (e.g., 'deliberate.cloud')"
  type        = string
}
