output "server_id" {
  description = "Hetzner server ID for GitLab"
  value       = var.enable_gitlab ? hcloud_server.gitlab[0].id : null
}

output "server_ipv4" {
  description = "Public IPv4 address of GitLab server"
  value       = var.enable_gitlab ? hcloud_server.gitlab[0].ipv4_address : null
}

output "server_ipv6" {
  description = "Public IPv6 address of GitLab server"
  value       = var.enable_gitlab ? hcloud_server.gitlab[0].ipv6_address : null
}

output "gitlab_url" {
  description = "GitLab web interface URL"
  value       = var.enable_gitlab ? local.gitlab_url : null
}

output "registry_url" {
  description = "GitLab container registry URL"
  value       = var.enable_gitlab ? local.registry_url : null
}

output "volume_id" {
  description = "Hetzner volume ID for GitLab data"
  value       = var.enable_gitlab ? hcloud_volume.gitlab_data[0].id : null
}

output "debug_ssh_private_key" {
  description = "SSH private key for debugging the GitLab server"
  value       = var.enable_gitlab ? tls_private_key.debug_ssh[0].private_key_pem : null
  sensitive   = true
}

output "k3s_admin_cert" {
  description = "K3s admin client certificate"
  value       = var.enable_gitlab ? tls_locally_signed_cert.k3s_admin[0].cert_pem : null
  sensitive   = true
}

output "k3s_admin_key" {
  description = "K3s admin client key"
  value       = var.enable_gitlab ? tls_private_key.k3s_admin[0].private_key_pem : null
  sensitive   = true
}

output "k3s_ca_cert" {
  description = "K3s cluster CA certificate"
  value       = var.enable_gitlab ? tls_self_signed_cert.k3s_ca[0].cert_pem : null
  sensitive   = true
}
