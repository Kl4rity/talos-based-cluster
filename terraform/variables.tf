variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "letsencrypt_email" {
  type        = string
  description = "Email address for Let's Encrypt certificate notifications"
}

variable "hetzner_dns_api_token" {
  type        = string
  description = "Hetzner DNS API token for DNS-01 challenges"
  sensitive   = true
}