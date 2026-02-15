output "server_id" {
  description = "Hetzner server ID for GitLab"
  value       = hcloud_server.gitlab.id
}

output "server_ipv4" {
  description = "Public IPv4 address of GitLab server"
  value       = hcloud_server.gitlab.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 address of GitLab server"
  value       = hcloud_server.gitlab.ipv6_address
}

output "gitlab_url" {
  description = "GitLab web interface URL"
  value       = local.gitlab_url
}

output "registry_url" {
  description = "GitLab container registry URL"
  value       = local.registry_url
}

output "volume_id" {
  description = "Hetzner volume ID for GitLab data"
  value       = hcloud_volume.gitlab_data.id
}
