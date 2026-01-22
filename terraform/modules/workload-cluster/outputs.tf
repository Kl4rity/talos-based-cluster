output "kubeconfig" {
  description = "Raw kubeconfig file for authenticating with the Kubernetes cluster"
  value       = module.kubernetes.kubeconfig
  sensitive   = true
}

output "kubeconfig_data" {
  description = "Structured kubeconfig data for the Kubernetes cluster"
  value       = module.kubernetes.kubeconfig_data
  sensitive   = true
}

output "talosconfig_data" {
  description = "Structured Talos configuration data"
  value       = module.kubernetes.talosconfig_data
  sensitive   = true
}