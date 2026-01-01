output "control_plane_servers" {
  description = "All control plane server details"
  value = {
    for server_key, server in hcloud_server.control_plane_nodes : server_key => {
      id          = server.id
      name        = server.name
      ipv4        = server.ipv4_address
      ipv6        = server.ipv6_address
      location    = server.location
      server_type = server.server_type
      image       = server.image
      labels      = server.labels
    }
  }
}

output "control_plane_ipv4_addresses" {
  description = "IPv4 addresses of all control plane servers"
  value       = [for server in hcloud_server.control_plane_nodes : server.ipv4_address]
}

output "control_plane_ipv6_addresses" {
  description = "IPv6 addresses of all control plane servers"
  value       = [for server in hcloud_server.control_plane_nodes : server.ipv6_address]
}

output "control_plane_names" {
  description = "Names of all control plane servers"
  value       = [for server in hcloud_server.control_plane_nodes : server.name]
}

output "control_plane_locations" {
  description = "Locations of all control plane servers"
  value       = { for server_key, server in hcloud_server.control_plane_nodes : server_key => server.location }
}