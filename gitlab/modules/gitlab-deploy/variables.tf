
variable "domains" {
  type        = list(string)
  description = "List of domains for the cluster"
}

variable "letsencrypt_email" {
  type        = string
  description = "Email for Let's Encrypt certificates"
}

variable "gitlab_root_password" {
  type        = string
  description = "GitLab root password (if provided)"
  sensitive   = true
  default     = null
}

variable "runner_registration_token" {
  type        = string
  description = "Registration token for GitLab Runners"
  sensitive   = true
  default     = null
}

variable "gitlab_chart_version" {
  type        = string
  description = "GitLab Helm chart version"
  default     = "9.8.4"
}
