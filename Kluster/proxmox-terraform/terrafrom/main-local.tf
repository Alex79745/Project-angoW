terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url         = var.proxmox_api_url
  pm_api_token_id    = var.proxmox_token_id # just in case
  pm_api_token_secret= var.proxmox_token_secret # just in case
  pm_tls_insecure    = true
}

resource "proxmox_vm_qemu" "masters" {
  for_each    = local.masters

  vmid        = each.value.vmid
  name        = each.key
  target_node = var.target_node
  clone       = "talos-v1.11-template"
  cores       = each.value.cores
  memory      = each.value.memory

  disk {
    storage = "local-lvm"
    size    = each.value.disk
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

resource "proxmox_vm_qemu" "workers" {
  for_each    = local.workers

  vmid        = each.value.vmid
  name        = each.key
  target_node = var.target_node
  clone       = "talos-v1.11-template"
  cores       = each.value.cores
  memory      = each.value.memory

  disk {
    storage = "local-lvm"
    size    = each.value.disk
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}
