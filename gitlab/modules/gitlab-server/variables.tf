variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "domains" {
  type        = list(string)
  description = "List of domains for the cluster"
}

variable "server_type" {
  type        = string
  description = "Hetzner server type"
  default     = "cx33"
}

variable "location" {
  type        = string
  description = "Hetzner datacenter location"
  default     = "nbg1"
}

variable "volume_size" {
  type        = number
  description = "Size of the data volume in GB"
  default     = 100
}

variable "gitlab_root_password" {
  type        = string
  description = "GitLab root password"
  sensitive   = true
}

variable "root_password" {
  type        = string
  description = "Root password for console access"
  sensitive   = true
}

variable "letsencrypt_email" {
  type        = string
  description = "Email for Let's Encrypt certificates"
}

variable "runner_registration_token" {
  type        = string
  description = "Registration token for GitLab Runners"
  sensitive   = true
}

variable "gitlab_image_tag" {
  type        = string
  description = "Docker image tag for GitLab CE"
  default     = "18.6.6-ce.0"
}
