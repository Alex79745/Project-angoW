locals {
  primary_control_node_name = one(keys(var.control_nodes))
  primary_control_node_ip   = var.control_node_ips[local.primary_control_node_name]

  control_node_ips = values(var.control_node_ips)
  worker_node_ips  = values(var.worker_node_ips)
  node_ips         = concat(local.control_node_ips, local.worker_node_ips)
}

resource "proxmox_virtual_environment_download_file" "talos_image" {
  content_type = "iso"
  datastore_id = var.proxmox_iso_datastore
  node_name    = values(var.control_nodes)[0]

  url = "https://factory.talos.dev/image/${var.talos_schematic_id}/v${var.talos_version}/metal-${var.talos_arch}.qcow2"

  file_name = "${var.talos_cluster_name}-talos-${var.talos_version}-${var.talos_arch}.img"
}

# ------------------------
# CONTROL PLANE VMs
# ------------------------
resource "proxmox_virtual_environment_vm" "talos_control_vm" {
  for_each  = var.control_nodes
  name      = each.key
  node_name = each.value

  agent {
    enabled = true
  }

  cpu {
    cores = var.proxmox_control_vm_cores
    type  = var.proxmox_vm_type
  }

  memory {
    dedicated = var.proxmox_control_vm_memory
    floating  = var.proxmox_control_vm_memory
  }

  disk {
    datastore_id = var.proxmox_image_datastore
    file_id      = proxmox_virtual_environment_download_file.talos_image.id
    interface    = "virtio0"
    size         = var.proxmox_control_vm_disk_size
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge  = var.proxmox_network_bridge
    vlan_id = var.proxmox_network_vlan_id
  }

  # ✅ NoCloud cloud-init (STATIC IP)
  initialization {
    interface = "scsi0"

    ip_config {
      ipv4 {
        address = lookup(var.control_node_ips, each.key, null)
        gateway = var.network_gateway
      }
    }

    #dns {
    #  servers = var.dns_servers
    #}
  }

  operating_system {
    type = "l26"
  }
}

# ------------------------
# WORKER VMs
# ------------------------
resource "proxmox_virtual_environment_vm" "talos_worker_vm" {
  for_each  = var.worker_nodes
  name      = each.key
  node_name = each.value

  agent {
    enabled = true
  }

  cpu {
    cores = var.proxmox_worker_vm_cores
    type  = var.proxmox_vm_type
  }

  memory {
    dedicated = var.proxmox_worker_vm_memory
    floating  = var.proxmox_worker_vm_memory
  }

  disk {
    datastore_id = var.proxmox_image_datastore
    file_id      = proxmox_virtual_environment_download_file.talos_image.id
    interface    = "virtio0"
    size         = var.proxmox_worker_vm_disk_size
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge  = var.proxmox_network_bridge
    vlan_id = var.proxmox_network_vlan_id
  }

  dynamic "disk" {
    for_each = lookup(var.worker_extra_disks, each.key, [])
    content {
      datastore_id = disk.value.datastore_id
      file_id      = disk.value.file_id
      file_format  = disk.value.file_format
      interface    = "virtio${disk.key + 1}"
      size         = disk.value.size
      discard      = "on"
      iothread     = true
    }
  }

  # ✅ NoCloud cloud-init (STATIC IP)
  initialization {
    interface = "scsi0"

    ip_config {
      ipv4 {
        address = lookup(var.worker_node_ips, each.key, null)
        gateway = var.network_gateway
      }
    }

    #dns {
    #  servers = var.dns_servers
    #}
  }

  operating_system {
    type = "l26"
  }
}

# ------------------------
# TALOS CONFIG
# ------------------------
resource "talos_machine_secrets" "talos_secrets" {}

data "talos_machine_configuration" "control_mc" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.primary_control_node_ip}:6443"
  machine_secrets  = talos_machine_secrets.talos_secrets.machine_secrets
}

data "talos_machine_configuration" "worker_mc" {
  cluster_name     = var.talos_cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${local.primary_control_node_ip}:6443"
  machine_secrets  = talos_machine_secrets.talos_secrets.machine_secrets
}

data "talos_client_configuration" "talos_client_config" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.talos_secrets.client_configuration
  endpoints            = local.control_node_ips
  nodes                = local.node_ips
}

resource "talos_machine_configuration_apply" "control_apply" {
  for_each = var.control_nodes

  client_configuration        = talos_machine_secrets.talos_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_mc.machine_configuration
  node                        = var.control_node_ips[each.key]
  config_patches              = var.control_machine_config_patches

  depends_on = [proxmox_virtual_environment_vm.talos_control_vm]
}

resource "talos_machine_configuration_apply" "worker_apply" {
  for_each = var.worker_nodes

  client_configuration        = talos_machine_secrets.talos_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker_mc.machine_configuration
  node                        = var.worker_node_ips[each.key]
  config_patches              = var.worker_machine_config_patches

  depends_on = [proxmox_virtual_environment_vm.talos_worker_vm]
}

resource "talos_machine_bootstrap" "bootstrap" {
  node                 = local.primary_control_node_ip
  client_configuration = talos_machine_secrets.talos_secrets.client_configuration
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [talos_machine_bootstrap.bootstrap]

  client_configuration = talos_machine_secrets.talos_secrets.client_configuration
  node                 = local.primary_control_node_ip
}
