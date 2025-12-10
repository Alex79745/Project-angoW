terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">=2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://192.168.1.129:8006/api2/json"
  $pm_api_token_id = "terraform@pam!token"
  $pm_api_token_secret = ""
  $pm_tls_insecure = true
  pm_password = "928195424"
  pm_user    = "root@pam"
}

locals {
  masters = {
    "talos-master-1" = { vmid = 200; cores = 2; memory = 2048; disk = 20; ip = "192.168.1.10/24" }
    "talos-master-2" = { vmid = 201; cores = 2; memory = 2048; disk = 20; ip = "192.168.1.11/24" }
    "talos-master-3" = { vmid = 202; cores = 2; memory = 2048; disk = 20; ip = "192.168.1.12/24" }
  }
  workers = {
    "talos-worker-1" = { vmid = 210; cores = 2; memory = 2048; disk = 20; ip = "192.168.1.20/24" }
    "talos-worker-2" = { vmid = 211; cores = 2; memory = 2048; disk = 20; ip = "192.168.1.21/24" }
  }
}

resource "proxmox_vm_qemu" "masters" {
  for_each = local.masters

  vmid          = each.value.vmid
  name          = each.key
  target_node   = "pve-node1"
  clone         = "talos-v1.11-template"
  cores         = each.value.cores
  memory        = each.value.memory
  disk {
    storage = "local-lvm"
    size    = each.value.disk
  }
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  # no cloud-init here, because Talos has its own config mechanism # documentation check 
}

resource "proxmox_vm_qemu" "workers" {
  for_each = local.workers

  vmid          = each.value.vmid
  name          = each.key
  target_node   = "pve-node1"
  clone         = "talos-v1.11-template"
  cores         = each.value.cores
  memory        = each.value.memory
  disk {
    storage = "local-lvm"
    size    = each.value.disk
  }
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}
