variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS-01 challenges"
  type        = string
  sensitive   = true
}

