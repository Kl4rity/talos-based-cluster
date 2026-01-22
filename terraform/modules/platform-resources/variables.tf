variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "hetzner_dns_api_token" {
  description = "Hetzner DNS API token for DNS-01 challenges"
  type        = string
  sensitive   = true
}