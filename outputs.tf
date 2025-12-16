# Talos configuration output
output "talos_config" {
  description = "Talos configuration file for the cluster"
  value       = data.talos_client_configuration.talos_client_config.talos_config
  sensitive   = true
}

# Kubeconfig output
output "kubeconfig" {
  description = "Raw Kubeconfig for accessing the Talos-managed cluster"
  value       = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive   = true
}
