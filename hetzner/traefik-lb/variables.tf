variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "load_balancer_name" {
  type        = string
  description = "Name of the Traefik load balancer"
  default     = "traefik-ingress"
}

variable "location" {
  type        = string
  description = "Location for the load balancer"
  default     = "nbg1"
}

variable "load_balancer_type" {
  type        = string
  description = "Type of load balancer"
  default     = "lb11"
}

variable "load_balancer_labels" {
  type        = map(string)
  description = "Labels to apply to the load balancer"
  default = {
    type = "traefik-ingress"
  }
}

variable "worker_target_label_selector" {
  type        = string
  description = "Label selector for worker nodes running Traefik"
  default     = "type=worker"
}

variable "http_listen_port" {
  type        = number
  description = "Port the load balancer listens on for HTTP traffic"
  default     = 80
}

variable "http_destination_port" {
  type        = number
  description = "Port HTTP traffic is forwarded to (Traefik NodePort)"
  default     = 32765
}

variable "http_protocol" {
  type        = string
  description = "Protocol for HTTP service"
  default     = "tcp"
}

variable "https_listen_port" {
  type        = number
  description = "Port the load balancer listens on for HTTPS traffic"
  default     = 443
}

variable "https_destination_port" {
  type        = number
  description = "Port HTTPS traffic is forwarded to (Traefik NodePort)"
  default     = 32031
}

variable "https_protocol" {
  type        = string
  description = "Protocol for HTTPS service"
  default     = "tcp"
}