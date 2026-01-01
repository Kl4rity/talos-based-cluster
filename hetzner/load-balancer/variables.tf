variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "load_balancer_name" {
  type        = string
  description = "Name of the load balancer"
  default     = "controlplane"
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
    type = "controlplane"
  }
}

variable "service_listen_port" {
  type        = number
  description = "Port the load balancer listens on"
  default     = 6443
}

variable "service_destination_port" {
  type        = number
  description = "Port traffic is forwarded to"
  default     = 6443
}

variable "service_protocol" {
  type        = string
  description = "Protocol for the service"
  default     = "tcp"
}

variable "controlplane_target_label_selector" {
  type        = string
  description = "Label selector for controlplane load balancer targets"
  default     = "type=controlplane"
}

variable "traefik_target_label_selector" {
  type        = string
  description = "Label selector for Traefik load balancer targets"
  default     = "app.kubernetes.io/name=traefik"
}

variable "http_listen_port" {
  type        = number
  description = "Port the load balancer listens on for HTTP traffic"
  default     = 80
}

variable "http_destination_port" {
  type        = number
  description = "Port HTTP traffic is forwarded to (Traefik HTTP port)"
  default     = 8000
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
  description = "Port HTTPS traffic is forwarded to (Traefik HTTPS port)"
  default     = 8443
}

variable "https_protocol" {
  type        = string
  description = "Protocol for HTTPS service"
  default     = "tcp"
}