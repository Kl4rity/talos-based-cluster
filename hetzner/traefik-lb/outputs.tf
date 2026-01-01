output "traefik_load_balancer_ip" {
  description = "IPv4 address of the Traefik load balancer"
  value       = hcloud_load_balancer.traefik.ipv4
}

output "traefik_load_balancer_ipv6" {
  description = "IPv6 address of the Traefik load balancer"
  value       = hcloud_load_balancer.traefik.ipv6
}

output "traefik_load_balancer_name" {
  description = "Name of the Traefik load balancer"
  value       = hcloud_load_balancer.traefik.name
}