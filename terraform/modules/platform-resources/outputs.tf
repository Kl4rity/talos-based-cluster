output "harbor_admin_password" {
  description = "Admin password for Harbor registry"
  value       = var.harbor_admin_password != null ? var.harbor_admin_password : random_password.harbor_admin_password[0].result
  sensitive   = true
}