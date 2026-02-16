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

variable "grafana_admin_password" {
  type        = string
  description = "Admin password for Grafana. If not provided, a secure random password will be generated."
  sensitive   = true
  default     = null
}

variable "enable_gitlab" {
  type        = bool
  description = "Enable GitLab CE deployment on dedicated Hetzner server"
  default     = true
}

variable "gitlab_server_type" {
  type        = string
  description = "Hetzner server type for GitLab (minimum CX33 recommended)"
  default     = "cx33"
}

variable "gitlab_server_location" {
  type        = string
  description = "Hetzner location for GitLab server"
  default     = "nbg1"
}

variable "gitlab_volume_size" {
  type        = number
  description = "Size of Hetzner volume for GitLab data in GB"
  default     = 100
}

variable "gitlab_root_password" {
  type        = string
  description = "Root password for GitLab. If not provided, a secure random password will be generated."
  sensitive   = true
  default     = null
}

variable "gitlab_server_root_password" {
  type        = string
  description = "Root password for GitLab server console access. If not provided, a secure random password will be generated."
  sensitive   = true
  default     = null
}

variable "gitlab_image_tag" {
  type        = string
  description = "Docker image tag for GitLab CE"
  default     = "18.6.6-ce.0"
}
