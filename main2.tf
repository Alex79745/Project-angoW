
terraform {
  required_version = ">= 1.4"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.51.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure
 
  username = var.proxmox_username
  password = var.proxmox_password
}

module "talos_node_01" {
  source              = "./modules/proxmox-talos-clone"

  # VM identity
  node_name           = var.node_name
  vm_id               = var.talos_vm_id
  name                = var.talos_name

  # Template reference
  template_vmid       = var.template_vmid

  # Hardware/storage/network (matches template defaults)
  datastore_id        = var.datastore_id
  disk_size_gb        = var.talos_disk_size_gb
  cpu_cores           = var.talos_cpu_cores
  cpu_sockets         = var.talos_cpu_sockets
  cpu_type            = var.talos_cpu_type
  memory_mb           = var.talos_memory_mb
  bridge              = var.talos_bridge

  # Talos machine config ()
  proxmox_host      = var.talos_hostname
  talos_hostname    = var.talos_hostname
  talos_ipv4_cidr     = var.talos_ipv4_cidr
  talos_ipv4_gw       = var.talos_ipv4_gw
  proxmox_username    = var.proxmox_username
  proxmox_password    = var.proxmox_password
}

output "talos_node_01_vm_id" {
  value = module.talos_node_01.vm_id
}
output "talos_node_01_name" {
  value = module.talos_node_01.name
}
