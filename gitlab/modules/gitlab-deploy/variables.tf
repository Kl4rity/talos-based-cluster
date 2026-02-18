variable "enable_gitlab" {
  type        = bool
  description = "Enable GitLab CE deployment"
  default     = true
}

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

variable "kube_host" {
  type        = string
  description = "Kubernetes API server URL for the dedicated GitLab K3s cluster"
}

variable "kube_client_certificate" {
  type        = string
  description = "PEM-encoded client certificate for Kubernetes auth"
  sensitive   = true
}

variable "kube_client_key" {
  type        = string
  description = "PEM-encoded client key for Kubernetes auth"
  sensitive   = true
}

variable "kube_cluster_ca_certificate" {
  type        = string
  description = "PEM-encoded cluster CA certificate for Kubernetes"
  sensitive   = true
}

variable "gitlab_chart_version" {
  type        = string
  description = "GitLab Helm chart version"
  default     = "9.8.4"
}
