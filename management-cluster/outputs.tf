output "server_ipv4" {
  description = "IPv4 address of the management server"
  value       = hcloud_server.management.ipv4_address
}

output "server_ipv6" {
  description = "IPv6 address of the management server"
  value       = hcloud_server.management.ipv6_address
}

output "server_id" {
  description = "ID of the management server"
  value       = hcloud_server.management.id
}

output "ssh_command" {
  description = "SSH command to access the server"
  value       = "ssh root@${hcloud_server.management.ipv4_address}"
}
