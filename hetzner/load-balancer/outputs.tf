output "load_balancer_id" {
  description = "ID of the created load balancer"
  value       = hcloud_load_balancer.controlplane.id
}

output "load_balancer_name" {
  description = "Name of the created load balancer"
  value       = hcloud_load_balancer.controlplane.name
}

output "load_balancer_ipv4" {
  description = "IPv4 address of the load balancer"
  value       = hcloud_load_balancer.controlplane.ipv4
}

output "load_balancer_ipv6" {
  description = "IPv6 address of the load balancer"
  value       = hcloud_load_balancer.controlplane.ipv6
}

output "load_balancer_type" {
  description = "Type of the load balancer"
  value       = hcloud_load_balancer.controlplane.load_balancer_type
}

output "service_details" {
  description = "Details of the load balancer service"
  value = {
    id               = hcloud_load_balancer_service.k8s_api.id
    listen_port      = hcloud_load_balancer_service.k8s_api.listen_port
    destination_port = hcloud_load_balancer_service.k8s_api.destination_port
    protocol         = hcloud_load_balancer_service.k8s_api.protocol
  }
}

output "target_selector" {
  description = "Label selector used for load balancer targets"
  value       = hcloud_load_balancer_target.controlplane_nodes.label_selector
}