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

variable "letsencrypt_email" {
  type        = string
  description = "Email for Let's Encrypt certificates"
}
