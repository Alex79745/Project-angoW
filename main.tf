terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.75.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7.1"
    }
  }
}


provider "proxmox" {
  endpoint = "https://192.168.1.129:8006/api2/json"
  username = "root@pam"
  password = "928195424"
  insecure = true
}


module "talos" {
  source  = "./modules/terraform-proxmox-talos-main/"
  #version = "0.1.5"

  # name of the cluster
  talos_cluster_name = "tf-test-cluster"
  # choose Talos version you want
  talos_version = "1.9.5"

  # Create exactly 1 control and 1 worker (both on the same proxmox node "pve1")
  control_nodes = {
    "tf-control-0" = "KHABC"
  }
  worker_nodes = {
    "tf-worker-0"  = "KHABC"
  }

   control_node_ips = {
    tf-control-0 = "192.168.1.11/24"
  }

  worker_node_ips = {
    tf-worker-0 = "192.168.1.12/24"
  }

  network_gateway = "192.168.1.1"
 
}

output "talos_config" {
  description = "Talos configuration file (sensitive)"
  value       = module.talos.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig file (sensitive)"
  value       = module.talos.kubeconfig
  sensitive   = true
}
