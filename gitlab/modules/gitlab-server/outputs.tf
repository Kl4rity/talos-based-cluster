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

output "debug_ssh_private_key" {
  description = "SSH private key for debugging the GitLab server"
  value       = tls_private_key.debug_ssh.private_key_pem
  sensitive   = true
}

output "k3s_admin_cert" {
  description = "K3s admin client certificate"
  value       = tls_locally_signed_cert.k3s_admin.cert_pem
  sensitive   = true
}

output "k3s_admin_key" {
  description = "K3s admin client key"
  value       = tls_private_key.k3s_admin.private_key_pem
  sensitive   = true
}

output "k3s_ca_cert" {
  description = "K3s cluster CA certificate"
  value       = tls_self_signed_cert.k3s_ca.cert_pem
  sensitive   = true
}
