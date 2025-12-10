resource "proxmox_virtual_environment_vm" "vm_test" {
  vm_id     = var.vm_id
  name      = var.vm_name
  node_name = var.node_name

  description = "(official bpg provider) clone template create one vm"
  on_boot     = true

  clone {
    vm_id = var.template_name
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.disk_storage
    interface    = "scsi0"
    size         = var.disk_size
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  # Cloud-init initialization block
  initialization {
    user_account {
      username = "ubuntu"
      password = "password"
    }

    ip_config {
      ipv4 {
        address = var.use_dhcp ? "dhcp" : "192.168.1.129/24"
        gateway = var.use_dhcp ? null : "192.168.1.1"
      }
    }
  }

  started = var.vm_state == "running" ? true : false
}
